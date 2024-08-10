
module wheel() {
    difference() {
        cylinder(20, 65, 65);
        translate([0,0,12]) cylinder(20, 60, 60);    
        translate([0,0,-12]) cylinder(20, 60, 60);  
        cylinder(80,5,5, center=true);    
    }

    difference() {
        cylinder(20, 10, 10);
        cylinder(80,5,5, center=true);  
    }

    n=11;
    for (i=[0:n-1])
        rotate([0,0,i*360/n]) translate([0,0,10]) rotate([0,90,0]) translate([0,0,5]) cylinder(55, 5, 8);
}

module tire() {
    
    n = 5;
    m = 60;
    for (i=[0:n-1])
        for (j=[0:m-1])
            rotate([0,0,(j+i%2/2)*360/m]) translate([68.5,0,5*i]) sphere(3);
                
    difference() {         
        minkowski() {
            cylinder(20, 65, 65);
            sphere(5);
        }
        cylinder(60, 62.5, 62.5, center=true);
        wheel();
    }
}

module entire_wheel() {
    color("blue") tire();
    color("gray") wheel();
}

entire_wheel();
