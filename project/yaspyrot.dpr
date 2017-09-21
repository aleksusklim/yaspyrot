program yaspyrot;

{$APPTYPE CONSOLE}

uses Classes,SysUtils,
ubagpack; // bagpack.pas

type offsetcount_=record
offset:Cardinal;
count:Cardinal;
end;

const md:array[0..3]of Integer=(4,3,2,1);md0:array[0..3]of Integer=(0,3,2,1);
f000=chr(255)+#0#0#0;

var
i,j,k,c,n,jump,cnt,size,obj,idx,len,res,memsize,last2,last:Integer;
WAD,SUBs,LVLs,TXT,ASTs:string;
SUB,LVL:Integer;
AST,SP2,ic,f:Boolean;
stream:TFileStream;
memory:TMemoryStream;
offsetcount,subsub:offsetcount_;
person:array [0..255] of string;
offset:array [0..255] of Integer;
table:array[0..255] of char;
ptrs:array of Integer;
save:Text;
list,ref,dubl,ff00:TStringList;
s,ss:string;
bagpack:TBagPack;

function seekptr(v:Integer):Boolean;
var i:Integer;
begin
Result:=true;
for i:=0 to Length(ptrs)-1 do if ptrs[i]=v then exit;
Result:=false;
end;

begin
if (ParamCount<4)or(ParamCount>5) then begin
WriteLn('Yet Another Spyro Texter v1.7, Kly_Men_COmpany! Usage:');
WriteLn('yaspyrot.exe "WAD" (SUB) (LVL) "TXT" ["SYM"]');
WriteLn('"WAD" = filename of wad.wad or extracted subfile of a level');
WriteLn('(SUB) = 0 if "WAD" is subfile; or a subfile number if it`s WAD.WAD');
WriteLn('(LVL) = 0 for Spyro2 and sublevel number for Spyro3');
WriteLn('"TXT" = filename to export or import texts');
WriteLn('["SYM"] = if present then do import, else export; this is 256-byte file');
WriteLn('           with character substitution; use shipped 256.256 as identity');
WriteLn('  Examples:');
WriteLn('yaspyrot G:\WAD.WAD 98 1 ss.txt');
WriteLn('yaspyrot.exe sub_100.wad 2 sv.txt font.dat');
WriteLn('yaspyrot ..\my 0 0 C:\test\sp2.txt 256.256');
WriteLn('');
exit;end;

res:=0;
WAD:=ParamStr(1);
SUBs:=ParamStr(2);
LVLs:=ParamStr(3);
TXT:=ParamStr(4);
ASTs:=ParamStr(5);

if not FileExists(WAD) then begin
WriteLn('WAD = "',WAD,'" not found!');
exit;end;

AST:=false;
if (ASTs<>'') then begin
if not FileExists(ASTs) then begin
WriteLn('AST = "',ASTs,'" not found!');
exit;end;
try
stream:=TFileStream.Create(ASTs,fmOpenRead or fmShareDenyNone);
size:=stream.Size;
stream.ReadBuffer(table,256);
stream.Free;
except
WriteLn('AST = "',ASTs,'" file open error!');
exit;end;
if size<>256 then begin
WriteLn('AST = "',ASTs,'" must be 256 bytes!');
exit;end;
AST:=true;
end;

if AST and not FileExists(TXT) then begin
WriteLn('TXT = "',TXT,'" not found!');
exit;end;

SUB:=StrToInt64Def(SUBs,-1);
if SUB=-1 then begin
WriteLn('SUB = "',SUBs,'" not a number!');
exit;end;

LVL:=StrToInt64Def(LVLs,-1);
if LVL=-1 then begin
WriteLn('LVL = "',LVLs,'" not a number!');
exit;end;

if LVL=0 then begin
SP2:=true;
LVL:=1;
end else SP2:=false;

try
if AST then stream:=TFileStream.Create(WAD,fmOpenReadWrite or fmShareDenyNone)
else stream:=TFileStream.Create(WAD,fmOpenRead or fmShareDenyNone);
except
WriteLn('WAD = "',WAD,'" file open error!');
exit;end;

try
if AST then begin
FileMode:=fmOpenRead;
Assign(save,TXT);
Reset(save);
end else begin
FileMode:=fmOpenWrite;
Assign(save,TXT);
Rewrite(save);
end;
except
WriteLn('WAD = "',WAD,'" file open error!');
exit;end;
ref:=TStringList.Create;
dubl:=TStringList.Create;
ff00:=TStringList.Create;
list:=TStringList.Create;
if AST then begin
ss:='';
while not eof(save) do begin
Readln(save,s);
s:=Trim(s);
if Copy(s,1,4)='ENG:' then begin
Delete(s,1,4);
ss:=Trim(s);
continue;
end;
if Copy(s,1,4)='RUS:' then begin
Delete(s,1,4);
s:=Trim(s);
if (s=ss) then n:=1 else n:=0;
for i:=1 to Length(s) do s[i]:=table[ord(s[i])];
list.AddObject(s,Ptr(n));
ss:='';
end;
end;
end;

idx:=0;
offsetcount.offset:=0;
offsetcount.count:=stream.Size;

if SUB>0 then begin
stream.Seek((SUB-1)*8,soFromBeginning);
try
stream.ReadBuffer(offsetcount,8);
except
WriteLn('WAD = "',WAD,'" at SUB = "',SUBs,'" read error!');
exit;end;
end;

if (offsetcount.count>10*1024*1024)or(offsetcount.count<4)
or(offsetcount.offset+offsetcount.count>stream.Size) then begin
WriteLn('SUB = "',SUBs,'" empty or too big!');
exit;end;

if LVL<2 then stream.Seek(offsetcount.offset+24,soFromBeginning)
else stream.Seek(offsetcount.offset+8+Cardinal(LVL)*16,soFromBeginning);

try
stream.ReadBuffer(subsub,8);
if (subsub.offset+subsub.count>offsetcount.count)or(subsub.count<4) then Abort;
except
WriteLn('LVL = "',LVLs,'" sublevel not exists');
exit;end;

stream.Seek(offsetcount.offset+subsub.offset,soFromBeginning);
memory:=TMemoryStream.Create();
subsub.offset:=stream.Position;
memory.CopyFrom(stream,subsub.count);

try
if SP2 then begin
memory.Seek(44,soFromBeginning);
for i:=1 to 8 do begin
memory.ReadBuffer(jump,4);
memory.Seek(jump-4,soFromCurrent);
end;
end else begin
memory.Seek(48,soFromBeginning);
for i:=1 to 12 do begin
memory.ReadBuffer(jump,4);
memory.Seek(jump-4,soFromCurrent);
end;
end;
except
WriteLn('LVL = "',LVL,'" seek error!');
exit;end;

bagpack:=TBagPack.Create;
obj:=memory.Position;
memory.ReadBuffer(size,4);
memory.ReadBuffer(cnt,4);
memsize:=obj+size+PInteger(PChar(memory.memory)+obj+size)^;

memory.Seek(obj,soFromBeginning);
for i:=1 to 3 do begin
memory.ReadBuffer(jump,4);
memory.Seek(jump-4,soFromCurrent);
end;
memory.ReadBuffer(jump,4);
if (jump<4) or (jump>16000) then exit;
SetLength(ptrs,jump);
for i:=0 to jump-1 do memory.ReadBuffer(ptrs[i],4);

for i:=0 to cnt-1 do begin
last:=bagpack.offsets.Count;
last2:=ff00.Count;
j:=1;
person[0]:='';
try
memory.Seek(obj+8+i*88,soFromBeginning);
memory.ReadBuffer(jump,4);
if jump<=0 then continue;
if (not seekptr(jump+12))or(not seekptr(jump+16)) then continue;
for n:=0 to dubl.Count-1 do if Integer(dubl.Objects[n])=jump then begin
jump:=0;
break;
end;
dubl.AddObject('',Ptr(jump));
memory.Seek(jump+8,soFromBeginning);
memory.ReadBuffer(jump,4);
//writeln(jump);if jump<>255 then Continue; // !?
offset[0]:=memory.Position;
memory.ReadBuffer(jump,4);
person[0]:=PChar(memory.memory)+jump;
len:=Length(person[0]);
if {((jump mod 4)<>0)or}(jump>memsize)or(jump<obj+size)then continue;
for k:=1 to len do
if (ord(person[0][k])<32)or(ord(person[0][k])>126) then begin
len:=0;
break;end;
if len<2 then offset[0]:=0 else begin
len:=len+md[len mod 4];
bagpack.AddSpace(jump,len);
end;

repeat
if (j>1)and(not seekptr(memory.Position)) then break;
memory.ReadBuffer(jump,4);
if (j>=255)or{((jump mod 4)<>0)or}(jump>memsize)or(jump<obj+size)then break;
k:=PByte(PChar(memory.memory)+jump)^;
if (k<>0) and (k<>255) then begin
offset[j]:=memory.Position-4;
person[j]:=PChar(memory.memory)+jump+k;
for n:=1 to Length(person[j]) do
if (ord(person[j][n])<32)or(ord(person[j][n])>126) then begin
person[j]:='';
break;
end;
if Length(person[j])<2 then continue;
len:=Length(person[j])+k;
len:=len+md[len mod 4];
bagpack.AddSpace(jump,len);
Inc(j);
end else begin
if (k=0) or (k=255) then begin
//bagpack.AddSpace(jump,4);
//if k=0 then ff00.AddObject('0',Ptr(memory.Position-4)) else ff00.AddObject('1',Ptr(memory.Position-4));
end;
end;
until false;
if j<=1 then abort;
f:=true;
for k:=0 to j-1 do if Length(person[k])>=2 then f:=false;
if f then Abort;
if AST then begin
n:=idx;
for k:=0 to j-1 do if (offset[k]>0) then begin
if(Integer(list.Objects[n])>0) then f:=true;
Inc(n);
end;
if f then begin
for k:=n-1 downto idx do list.Delete(k);
Abort;
end;
end;
except
bagpack.offsets.Count:=last;
bagpack.counts.Count:=last;
while ff00.Count>last2 do ff00.Delete(ff00.Count-1);
continue;end;

if AST then begin
for k:=0 to j-1 do if offset[k]>0 then begin
if idx>=list.Count then begin
WriteLn('TXT = "',TXT,'" not enough strings!');
exit;end;
s:=list.Strings[idx];
memory.Seek(offset[k],soFromBeginning);
memory.ReadBuffer(jump,4);
if k=0 then c:=0 else c:=PByte(PChar(memory.memory)+jump)^;
len:=c+Length(s)+1;
s:=StringOfChar('_',c)+s+#0;
UniqueString(s);
Move(PByte(PChar(memory.memory)+jump)^,PChar(s)^,c);
list.Objects[idx]:=Ptr(offset[k]);
for n:=0 to idx-1 do
if list.Strings[n]=s then begin
ref.AddObject(s,list.Objects[idx]);
s:='';
break;
end;
list.Strings[idx]:=s;
if s<>'' then bagpack.AddItem(idx,len);
Inc(idx);
end;
end else begin
Writeln(save,'----'#9,i,#9'----');
Writeln(save,'');
for k:=0 to j-1 do if offset[k]>0 then begin
Inc(res);
Writeln(save,'ENG:'#9,person[k]);
Writeln(save,'RUS:'#9,person[k]);
Writeln(save,'');
end;
end;
end;

if idx<>list.Count then begin
WriteLn('TXT = "',TXT,'" too much strings!');
exit;end;

if AST then begin

if ff00.Count>0 then begin
list.AddObject(f000,Ptr(0));
bagpack.AddItem(idx,4);
end;

for i:=0 to bagpack.offsets.Count-1 do
Move(PChar(StringOfChar('_',Cardinal(bagpack.counts[i])))^,PChar(PChar(memory.memory)+Cardinal(bagpack.offsets[i]))^,Cardinal(bagpack.counts[i]));
len:=bagpack.Compute();
Inc(len,md0[len mod 4]);
res:=len;

i:=PInteger(PChar(memory.memory)+obj+size)^+len;

Dec(size,len);
if (cnt+1)*88>size then begin
WriteLn('TXT = "',TXT,'" text too long...');
exit;end;

PInteger(PChar(memory.memory)+obj)^:=size;
memory.Seek(obj+size,soFromBeginning);
memory.WriteBuffer(i,4);
Inc(size,4);

for i:=0 to bagpack.items.Count-1 do begin
n:=Cardinal(bagpack.items[i]);
s:=list.Strings[n];
if Cardinal(bagpack.offsets[i])=0 then memory.Seek(Cardinal(obj+size)+Cardinal(bagpack.counts[i]),soFromBeginning)
else memory.Seek(Cardinal(bagpack.counts[i]),soFromBeginning);
jump:=Integer(list.Objects[n]);
if jump=0 then begin
for n:=0 to ff00.Count-1 do if ff00.Strings[n]='0' then PInteger(PChar(memory.memory)+Integer(ff00.Objects[n]))^:=memory.Position+2 else PInteger(PChar(memory.memory)+Integer(ff00.Objects[n]))^:=memory.Position;
end else begin
PInteger(PChar(memory.memory)+jump)^:=memory.Position;
for n:=0 to ref.Count-1 do if ref.Strings[n]=s then PInteger(PChar(memory.memory)+Integer(ref.Objects[n]))^:=memory.Position;
end;
memory.WriteBuffer(PChar(s)^,Length(s));
end;

memory.Seek(0,soFromBeginning);
stream.Seek(subsub.offset,soFromBeginning);
stream.CopyFrom(memory,subsub.count);
end;

bagpack.Free;
stream.Free;
ref.Free;
dubl.Free;
ff00.Free;
list.Free;
memory.Free;
Close(save);

if AST then begin
Writeln('Done: ',res,' bytes allocated');
end else begin
Writeln('Done: ',res,' strings found');
end;
end.

