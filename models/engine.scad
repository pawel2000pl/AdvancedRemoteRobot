
module engine() {
    translate([0,0,18.5])
    rotate([90,0,0]) {
        translate([0,0,-15.5]) difference() {
            translate([0,0,8.1]) cylinder(56, 35.5/2, 35.5/2, center=true);    
            translate([0,0,-20.4]) cylinder(2, 34.4/2, 34.4/2, center=true);     
        }        
        
        translate([0,0,-35.9]) cylinder(5, 5.15, 5.15, center=true);
        translate([0,22.6/2,-35.6]) cube([5, 1, 7], center=true);
        translate([0,-22.6/2,-35.6]) cube([5, 1, 7], center=true);
        
        translate([0,0,8.44]) cylinder(24.4, 37/2, 37/2, center=true);    
        
        translate([0,7,23.65]) {
            cylinder(6.2, 6, 6, center=true);
            translate([0,0,10.27]) difference() {
                cylinder(14.4, 3, 3, center=true);
                translate([0,1+3-0.6,1.1]) cube([5,2,12.3], center=true);
            }
        }
    }
}

engine();