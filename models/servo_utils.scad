use <utils.scad>

$servo_draglift_offset = 5.5;

function get_servo_draglift_offset() = $servo_draglift_offset;

module draglift() {
    color("white") {
        hull() {
            cylinder(1.5,3,3);
            clone_mirror([1,0,0]) translate([25.5,0,0]) cylinder(1.5,2,2);
        }
        mirror([0,0,1]) cylinder(2.5,3,3);
    }
}

module draglift_holder() {
    difference() {
        union() {
            cube([30, 5, 2]);
            clone_mirror([1,0,0]) clone_mirror([0,1,0])
                cube([30, 5, 2]);
        }
        draglift();
    }
}

module draglift_holder_aligned_to_servo() {
    translate([$servo_draglift_offset,0,17]) draglift_holder();
}

//draglift_holder();

module servo_screws() {
    color("gray") clone_mirror([1,0,0]) translate([14,0,6]) 
        cylinder(20,1.75/2,1.75/2, center=true);
}
servo_screws();

module servo(draw_draglift=true, draglift_angle=0) {
    color("blue") {
        cube([23,12,21], center=true);
        difference() {
            translate([0,0,6.5]) cube([32,9,2], center=true);
            servo_screws();
        }
        translate([0,0,10.5]) cylinder(3.5, 3, 3);
        translate([0,0,14]) cylinder(1,1,1);
    }
    translate([$servo_draglift_offset,0,10.5]) {
        color("blue") cylinder(3.5,6,6);
        color("white") cylinder(6,1.8,1.8);
    }
    if (draw_draglift)
        translate([$servo_draglift_offset,0,17]) rotate([0,0,draglift_angle]) draglift();
}

servo();