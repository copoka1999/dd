{$A-,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q+,R+,S+,T-,V-,X+}
{$M 16384,0,655360}
uses crt,dos;
type int13=record
ps:byte;
res1:byte;
ns:byte;
res2:byte;
asi:word;
ads:word;
sect:longint;
res3:longint;
res4:longint;
res5:longint;
end ;
var pn:string;
    fn:string;
    dsk:string;
    f:file;
    dns:longint;
    i13:int13;
    a:array[0..63*512-1] of byte;
    p1:string;
    info:array[0..511] of byte;
    d,x:word;
function lba40(func:byte;disk:byte;sect:longint;ns:byte):byte;
var errora:byte;
begin
 i13.ps:=$10; {packet size}
 i13.res1:=0;
 i13.res2:=0;
 i13.res3:=0;
 i13.res4:=0;
 i13.res5:=0;
 i13.ns:=ns;
 i13.asi:=ofs(a);
 i13.ads:=seg(a);
 i13.sect:=sect;
 asm
  pusha
  mov ah,func
  mov dl,disk
  mov si,offset i13
  int 13h
  mov errora,ah
  popa
 end ;
 lba40:=errora;
end ;
procedure get_info(dsk:byte);
begin
 fillchar(info,sizeof(info),#0);
 info[0]:=74;
 asm
  nop
  nop
  nop
  mov dl,dsk
  mov ah,48h
  mov si,offset info
  int 13h
 end ;
 move(info[16],dns,4);
end ;
procedure create_disk(fn:string);
var x,sz:word;
begin
 assign(f,fn);
 setfattr(f,0);
 rewrite(f,1);
 sz:=(sizeof(a) div 2) -1;
 for x:=0 to sz do
 begin
  move(x,a[x*2],2);
 end ;
 blockwrite(f,a,sizeof(a));
 blockwrite(f,a,sizeof(a));
 blockwrite(f,a,4096);
 getfattr(f,x);
 x:=1;
 close(f);
 setfattr(f,x);
 x:=ioresult;
 halt;
end ;
procedure file2disk(fn:string;d:string);
var disk:byte;
    sect:longint;
    x:word;
    ns:word;
    sz:word;
    st,st1:string;
begin
 val(d,disk,x);
 assign(f,fn);
 filemode:=0;
 reset(f,1);
 if ioresult<>0 then
 begin
  writeln('Error open file '+fn);
  halt;
 end ;
 sect:=0;
 sz:=sizeof(a);
 repeat
  fillchar(a,sz,#0);
  blockread(f,a,sz,x);
  ns:=x div 512;
  st1:='';
  str(sect,st);
  st1:=st1+'Sector='+st;
  str(dns,st);
  st1:=st1+'/'+st;
  str(sz,st);
  st1:=st1+' size='+st;
  str(ns,st);
  st1:=st1+' read='+st;
  gotoxy(1,wherey);
  write(st1);
  lba40($43,disk,sect,ns);
  sect:=sect+63;
 until x<>sz;
 close(f);
 writeln;
 writeln('Complete.');
end ;
procedure disk2file(fn:string;d:string);
var disk:byte;
    sect:longint;
    x:word;
    ns:word;
    sz:word;
    st,st1:string;
    err:byte;

begin
 val(d,disk,x);
 assign(f,fn);
 setfattr(f,0);
 filemode:=2;
 rewrite(f,1);
 if ioresult<>0 then
 begin
  writeln('Error file '+fn);
  halt;
 end ;
 sect:=0;
 sz:=sizeof(a);
 ns:=63;
 repeat
  fillchar(a,sz,#0);
  err:=lba40($42,disk,sect,ns);
  blockwrite(f,a,sz);
  st1:='';
  str(sect,st);
  st1:=st1+'Sector='+st;
  str(dns,st);
  st1:=st1+'/'+st;
  str(sz,st);
  st1:=st1+' size='+st;
  str(ns,st);
  st1:=st1+' read='+st;
  gotoxy(1,wherey);
  write(st1);
  sect:=sect+63;
 until err<>0;
 close(f);
 setfattr(f,1);
 writeln;
 writeln('Complete.');
end ;
begin
 if paramcount<>3 then
 begin
  pn:=paramstr(0);
  writeln('Use '+pn+' mode file -> disk.');
  writeln('Mode=-r read disk -> write to file. Ex. -r c:\disk $81');
  writeln('Mode=-w read from file -> write to disk. Ex. -w c:\disk $81 ');
  writeln('Mode=-c create test disk image. Ex. -c c:\disk $81 ');
  halt;
 end ;
 if paramcount=3 then
 begin
  p1:=paramstr(1);
  fn:=paramstr(2);
  dsk:=paramstr(3);
  val(dsk,d,x);
  get_info(d);
  if (p1='-c')or(p1='-C') then
  begin
   writeln('Create disk '+fn);
   create_disk(fn);
   halt;
  end ;
  if (p1='-w')or(p1='-W') then
  begin
   writeln('Write disk from '+fn+ ' to disk '+dsk);
   file2disk(fn,dsk);
   halt;
  end ;
  if (p1='-r')or(p1='-R') then
  begin
   writeln('Read disk '+dsk+ ' write to file '+fn);
   disk2file(fn,dsk);
   halt;
  end ;
  writeln('Unknown parametr '+p1);
 end ;
end .