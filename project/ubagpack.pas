unit ubagpack;

interface

uses Classes,SysUtils;

type TBagPack=class(TObject)
public
offsets,counts,items,sizes:TList;
constructor Create;
destructor Destroy;override;
procedure AddSpace(Offset,Count:Cardinal);
procedure AddItem(Item,Size:Cardinal);
function Compute:Cardinal;
end;

implementation

type part=record
Offset,Count:Cardinal;
end;

constructor TBagPack.Create;
begin
inherited Create;
offsets:=TList.Create;
counts:=TList.Create;
items:=TList.Create;
sizes:=TList.Create;
end;

destructor TBagPack.Destroy;
begin
offsets.Free;
counts.Free;
items.Free;
sizes.Free;
inherited Destroy;
end;

procedure TBagPack.AddSpace(Offset,Count:Cardinal);
begin
if Count=0 then exit;
offsets.Add(Ptr(Offset));
counts.Add(Ptr(Count));
end;

procedure TBagPack.AddItem(Item,Size:Cardinal);
begin
if Size=0 then Size:=1;
items.Add(Ptr(Item));
sizes.Add(Ptr(Size));
end;

function TBagPack.Compute:Cardinal;
var i,j,k:Integer;
p:array of part;
n,m,t,s:Cardinal;
a,b,c:array of Cardinal;
d:array of Integer;

function bag(f:Cardinal):Boolean;
var i:Integer;
r:Boolean;
begin
Result:=true;
if f>=n then exit;
for i:=0 to m-1 do if b[f]<=a[i] then begin
d[f]:=i;
Dec(a[i],b[f]);
r:=bag(f+1);
Inc(a[i],b[f]);
if r then exit;
end;
if f>t then t:=f;
Result:=false;
end;

begin
SetLength(p,offsets.Count);
k:=0;

if (items.Count=0)or(offsets.Count=0) then begin
items.Clear;
sizes.Clear;
offsets.Clear;
counts.Clear;
Result:=0;
exit;
end;

//y:=0;for i:=0 to counts.Count-1 do Inc(y,Integer(counts[i]));Writeln('* ',y);

while true do begin
j:=-1;
for i:=0 to offsets.Count-1 do if Cardinal(offsets[i])<>Cardinal(-1) then
if (j=-1) or (Cardinal(offsets[i])<Cardinal(offsets[j])) then j:=i;
if (j=-1) or (Cardinal(offsets[j])=Cardinal(-1)) then break;
p[k].Offset:=Cardinal(offsets[j]);
p[k].Count:=Cardinal(counts[j]);
offsets[j]:=Ptr(-1);
if k>0 then begin
//Writeln('');Writeln(p[k-1].Offset,':',p[k-1].Count,#9,p[k].Offset,':',p[k].Count);Writeln('');
if p[k-1].Offset+p[k-1].Count>=p[k].Offset then begin
if p[k].Count+(p[k].Offset-p[k-1].Offset)>p[k-1].Count then
p[k-1].Count:=p[k].Count+(p[k].Offset-p[k-1].Offset);
end else Inc(k);
end else Inc(k);
end;

SetLength(a,k);
for i:=0 to k-1 do a[i]:=p[i].Count;
j:=items.Count;
SetLength(b,j);
SetLength(c,j);
SetLength(d,j);

k:=0;
while true do begin
j:=-1;
for i:=0 to sizes.Count-1 do if Cardinal(sizes[i])<>Cardinal(-1) then
if (j=-1) or (Cardinal(sizes[i])>Cardinal(sizes[j])) then j:=i;
if (j=-1) or (Cardinal(sizes[j])=Cardinal(-1)) then break;
b[k]:=Cardinal(sizes[j]);
c[k]:=Cardinal(items[j]);
sizes[j]:=Ptr(-1);
Inc(k);
end;
m:=Length(a);
n:=items.Count;
for i:=0 to n-1 do d[i]:=-1;

//y:=0;for i:=0 to m-1 do Inc(y,a[i]);Writeln('* ',y);

{
Writeln('');
Writeln(m);
for i:=0 to m-1 do begin
Writeln(a[i],' ');
end;
Writeln('');
Writeln(n);
for i:=0 to n-1 do begin
Writeln(b[i],' ');
end;
}

{
// 1
for s:=0 to n-1 do begin
i:=-1;for k:=0 to n-1 do if ((i=-1)or(b[k]>b[i]))and(d[k]=-1) then i:=k;
j:=-1;for k:=0 to m-1 do if ((j=-1)or(a[k]>a[j])) then j:=k;
if b[i]>a[j] then begin
d[i]:=-2;
end else begin
d[i]:=j;
Dec(a[j],b[i]);
end;
end;
//}

{
//2
while true do begin
j:=-1;for k:=0 to m-1 do if ((j=-1)or(a[k]<a[j]))and(a[k]>0) then j:=k;
if j=-1 then break;
i:=-1;for k:=0 to n-1 do if ((i=-1)or(b[k]>b[i]))and(d[k]=-1)and(b[k]<=a[j]) then i:=k;
if i=-1 then begin
a[j]:=0;
end else begin
d[i]:=j;
Dec(a[j],b[i]);
end;
end;
//}

//{
// 3
for s:=0 to n-1 do begin
i:=-1;for k:=0 to n-1 do if ((i=-1)or(b[k]>b[i]))and(d[k]=-1) then i:=k;
j:=-1;for k:=0 to m-1 do if ((j=-1)or(a[k]<a[j]))and(a[k]>0)and(b[i]<=a[k]) then j:=k;
if j=-1 then begin
d[i]:=-2;
end else begin
d[i]:=j;
Dec(a[j],b[i]);
end;
end;
//}

{
while n>0 do begin
t:=0;
if bag(0) then break;
Dec(n);
d[n]:=-1;
s:=b[n];b[n]:=b[t];b[t]:=s;
s:=c[n];c[n]:=c[t];c[t]:=s;
end;
//}

n:=Length(b);
offsets.Count:=n;
counts.Count:=n;
items.Count:=n;
sizes.Count:=n;

j:=0;
for i:=0 to n-1 do if d[i]<0 then offsets[i]:=Ptr(0) else offsets[i]:=Ptr(p[d[i]].Offset);
for i:=0 to n-1 do begin
items[i]:=Ptr(c[i]);
sizes[i]:=Ptr(b[i]);
if d[i]<0 then begin
counts[i]:=Ptr(j);
Inc(j,b[i]);
end else begin
counts[i]:=Ptr(p[d[i]].offset);
Inc(p[d[i]].offset,b[i]);
end;
end;

Result:=j;

{
for i:=0 to n-1 do begin
Writeln(
Integer(items[i]),#9,
Integer(sizes[i]),#9,
Integer(offsets[i]),#9,
Integer(counts[i]),#9,
Integer(d[i]));
end;
Writeln(j);
//}

end;

end.


