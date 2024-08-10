module back_wheel_srew_holes() {
    left = 33/2-3-2;
    forward = 20-2.5-3;
    translate([0,0,-2]) {
        translate([forward,left,0]) cylinder(50,2,2);
        translate([forward,-left,0]) cylinder(50,2,2);
        translate([-forward,left,0]) cylinder(50,2,2);
        translate([-forward,-left,0]) cylinder(50,2,2);
    }
}

module back_wheel() {
    difference() {
         mirror([1,0,0]) mirror([0,0,1]) translate([0,0,0.5]) {

            cube([38,33,1], center=true);
            translate([0,0,1]) cylinder(2,15,12);

            translate([0,0,1]) cylinder(2,15,12);
            translate([0,0,3]) cylinder(2,10,10);
            translate([0,0,5]) {
                difference() {
                    union() {
                        cylinder(3.5,12,13.5);
                        translate([0,0,3.5]) cylinder(17.5,13.5,13.5);
                        translate([9,0,10.5]) cube([28,19,21], center=true);
                    }        
                    translate([0,0,1]) cylinder(2.5,11,12.5);
                    translate([0,0,3.5]) cylinder(17.5,12.5,12.5);
                    translate([9,0,11.5]) cube([28,17,21], center=true);
                    translate([-15,0,18.5]) cube([30,30,30], center=true);
                    translate([-5.5,0,24]) rotate([0,30,0]) cube([30,30,30], center=true);
                    translate([35,0,10]) rotate([0,15,0]) cube([30,30,30], center=true);
                }
            }

            translate([15,0,21]) rotate([90,0,0]) {
                difference() {
                    cylinder(14,12.5,12.5, center=true);
                    cylinder(14,9,9, center=true);
                }
                cylinder(14,4.5,4.5, center=true);
                cylinder(4,9,9, center=true);
                cylinder(20,3,3, center=true);
            }
            
        }
        back_wheel_srew_holes();
    }
}  
   

back_wheel();