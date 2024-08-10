
//promień wewnętrzny, szerokość obręczy, grubość obręczy, szerokośc pinu, grubość pinu
module wheel_pin(r=6,w=2,d=1,pw=2,pd=2) {
    
    difference() {
        cylinder(d, r+w, r+w);
        cylinder(d, r, r);
    }
    
    translate([-r+w,-pw/2,0]) cube([2*r, pw, pd]);
    
}

wheel_pin();
