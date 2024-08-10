
module distance_sensor() {
    cube([7.1, 7.1, 12], center=true);
}

module side_distance_meter(with_holes=true) {
    
    difference() {
        cube([9,9,100], center=true);
        if (with_holes) {
            translate([0,0,-5]) cube([7.1,7.1,100], center=true);
            translate([-9,0,0]) cube([11,7.1,7.1], center=true);
            translate([-9,0,45]) cube([11,7.1,7.1], center=true);
        }
        
        translate([0,0,45]) rotate([0,90,0]) distance_sensor();
        rotate([0,90,0]) distance_sensor();
    }
    
    translate([-9,0,0]) difference() {
        cube([10,9,9], center=true);
        if (with_holes) 
            cube([11,7.1,7.1], center=true);
    }
    
    translate([-9,0,45]) difference() {
        cube([10,9,9], center=true);
        if (with_holes) 
            cube([11,7.1,7.1], center=true);
    }
}

side_distance_meter();
