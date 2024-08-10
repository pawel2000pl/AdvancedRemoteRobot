use <servo_utils.scad>;
use <utils.scad>

module camera_holder_servos() {
    clone_mirror([0,1,0]) 
        translate([-get_servo_draglift_offset(),55,2]) 
        rotate([90,0,0]) {
            servo(true, 0);            
            servo_screws();
        }
    translate([-get_servo_draglift_offset(),0,-10]) {
        servo();
        servo_screws();
    }
}

module camera_holder_sides() {
    difference() {
        translate([-20,0,2]) 
            cube([75,98,15], center=true);
        
        cube([90,85,30], center=true);
        camera_holder_servos();
    }
} 
camera_holder_sides();

module camera_holder_low() {
    difference() {
        union() {
            translate([0,0,-4.4]) cylinder(10,35,35);
            translate([-get_servo_draglift_offset(),0,-1.9]) 
                cube([35,15,5], center=true);
        }
        translate([0,0,3]) cylinder(3.1,30,30);    
        camera_holder_servos();
    }
    
    difference() {
        translate([0,0,0.6]) cube([60,75,10], center=true);
        cylinder(6,35,35);
        camera_holder_servos();
    }
}
camera_holder_low();

module camera_holder_up() {
    
    translate([0,0,3.1]) difference() {
        cylinder(6-0.1,29,29);
        translate([0,0,-0.1]) cylinder(7,26,26);                
        translate([0,0,4]) draglift();  
        translate([0,0,3]) draglift();  
    }
    difference() {
        translate([0,0,7]) cylinder(2,29,29);
        cylinder(50,1.5,1.5);
        camera_holder_servos();        
        translate([0,0,6]) draglift();
    }
    
    clone_translate([-23,0,0]) {
        intersection() {
            translate([17,0,34]) 
                cube([10,35,50], center=true);
            difference() {
                minkowski() {
                    camera();
                    cube(6, center=true);
                }
                camera();                
                cube([100,14,200], center=true);
            }
        }          
        difference() {
            translate([17,0,24]) cube([10,35,30], center=true);
            camera();
        }
    }
    
}
camera_holder_up();


module camera() {
    translate([15,0,35]) rotate([0,90,0]) 
        cylinder(55,29/2,29/2, center=true);
}
if ($preview) {
    color("gray", 0.7) camera();
    camera_holder_servos();
}

module camera_holder(servos=true) {
    if (servos)
        camera_holder_servos();
    camera_holder_sides();
    camera_holder_low();
    camera_holder_up();
}






