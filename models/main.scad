use <odroid.scad>;
use <engine.scad>;
use <Bearing.scad>;
use <wheel.scad>;
use <gears.scad>;
use <wheel_pin.scad>;
use <side_distance_meter.scad>;
use <back_wheel.scad>;
use <utils.scad>;
use <camera_holder.scad>;

forward_axis_vector = [60,0,-14.5];


module computer() {
    translate([-110,2,-35])
    rotate([0,0,270])
    translate([-40, -30, 0])
    odroid_xu4(1);
}

module distance_sensors() {
    clone_mirror([0,1,0]) {
        translate([155,50,0]) rotate([0,90,0]) distance_sensor();
        translate([149,75,-40]) cube([5,5,100]);
        translate([155,75,-40]) rotate([0,90,0]) distance_sensor();
        translate([-155,55,-30]) rotate([0,90,0]) distance_sensor();     
        translate([-155,75,-10]) rotate([0,90,0]) distance_sensor();     
    }
}


module bearings(cutoff=0) {    
    clone_mirror([0,1,0]) translate(forward_axis_vector) clone_translate([0,-60,0]) translate([0,71,0]) rotate([90,0,0]) {
         if (cutoff == 0) bearing(5,15,12,coverThicknessRatio=0);
         if (cutoff == 1) cylinder(12,15,15,center=true);
         if (cutoff == 2) cylinder(12,5,5,center=true);   
         if (cutoff == 3) difference() {
            cylinder(12,15,15,center=true);
            cylinder(12,5,5,center=true);  
         }          
    }
}

module wheel_gear() {
    union() {
        bevel_herringbone_gear(modul=2, tooth_number=15,  partial_cone_angle=45, tooth_width=14, bore=4, pressure_angle=20, helix_angle=20);
        cylinder(11, 13.375, 5);
    }
}


module spindles_pins(back_rotate=false) {
    clone_mirror([0,1,0]) translate([0,105,0]) translate(forward_axis_vector) rotate([270, back_rotate ? -90 : 90,0]) wheel_pin();
}


module spindles() {
    difference() {
        clone_mirror([0,1,0]) translate([0,56,0]) translate(forward_axis_vector) rotate([270,0,0]) {
            difference() {
                translate([0,0,3]) cylinder(106,5,5,center=true);     
                translate([0,-5,3]) cube([10,5,106],center=true);  
            }
            translate([0,0,-37]) cube([12,2,2], center=true);
            translate([0,0,-35]) cube([12,2,2], center=true);        
        }          
        minkowski() {
            spindles_pins(); 
            cube(0.5);
        }
    }
}


module speedometer() {
    n = 16;
    d = 3;
    difference() {
        clone_mirror([0,1,0]) translate([0,22,0]) translate(forward_axis_vector) rotate([270,0,0]) {    
            difference() {
                translate([0,0,-1]) cylinder(7,6,6);            
                translate([0,0,2]) cylinder(0.1,10,10);     
                translate([0,0,2.4]) cylinder(0.1,10,10);           
            }
            translate([0,0,1.4]) difference() {
                cylinder(2,18.5,18.5, center=true);
                for (i=[0:n-1])
                    rotate([0,0,i*360/n]) translate([0,16,0]) cube([d,3,3], center=true);
            }
        }        
        spindles();
    }     
}

module spindles_gears() {
    difference() {
        clone_mirror([0,1,0]) translate([0,55,0]) translate(forward_axis_vector) rotate([270,0,0]) translate([0,0,-27.5]) wheel_gear();
        spindles();
    }
}

module back_wheel_balancer() {
    translate([-130,0,-62.5]) rotate([0,90,0]) back_balancer();
}


module wheels() {
    difference() {
        clone_mirror([0,1,0]) translate([60,105,-14.5]) rotate([90,0,0]) wheel();
        spindles();
        minkowski() {
            union() {
                spindles_pins(false); 
                spindles_pins(true);
            }
            cube(0.5);
        }
        clone_mirror([0,1,0]) translate([60,101.8,-15]) cube([30,2.5,2.5], center=true);
    }
}

module spindles_distances() {
    difference() {
        clone_mirror([0,1,0]) translate([60,85,-14.5]) rotate([90,0,0]) union() {
            cylinder(25,7,7);
            cylinder(45.5,5,5);
        }
        wheels();
        bearings(1);
        spindles();
    }
}

module tires() {
    clone_mirror([0,1,0]) translate([60,105,-14.5]) rotate([90,0,0]) tire();
}

module wheels_cutoff() {
    clone_mirror([0,1,0]) translate([60,87,-14.5]) rotate([90,0,0]) cylinder(10, 80, 80);
}

module acumulator() {
    translate([0,0,0])
    rotate([0,0,90])
    cube([135,70,65], center=true);
}


module engines() {
    translate([110,0,-40]) {
        clone_mirror([0,1,0])
        translate([0,45,0])
        rotate([0,0,270])
        engine();
    }
}

module engine_gears() {
    difference() {
        translate(forward_axis_vector) clone_mirror([0,1,0]) translate([17.5,45,0]) rotate([0,270,0]) rotate([0,0,180/15]) mirror([1,1,0]) {
            difference() {
                union() {
                    wheel_gear();
                    translate([0,0,-2]) cylinder(4,13.5,13.5, center=true);    
                }
                cylinder(20,2.5,2.5);     
            //}   
                rotate([90,90,180/15]) translate([-6,0,3.85]) hull() {
                    cylinder(3,4.01,4.01, center=true);
                    translate([20,0,0]) cylinder(3,4.01,4.01, center=true);
                }
            }
        }
        engines();
    }
}

module first_print_area() {
    translate([60,0,50]) color("blue", 0.1) cube(200, center=true);
}

module second_print_area() {
    translate([-140,0,50]) color("cyan", 0.1) cube(200, center=true);
}

module amortisators() {
    difference() {
        clone_mirror([0,1,0]) translate([-150,80,-70]) {
            clone_mirror([0,0,1]) translate([0,0,-0.5]) rotate([90,0,0]) cos3d(150, 25, 25, 5);
            difference() {
                translate([10,-12.5,10]) cube([25,25,25], center=true);
                translate([10,-12.5,7]) cube([20,20,30], center=true);
            }
            translate([10,-12.5,-7.5]) cube([18,18,25], center=true);
        }
        first_print_area();
    }
}

module engine_holder_holder() {
    translate([100,0,5]) minkowski() {
        cube([10,150,5],center=true);
        sphere(5);
    }
}

module engine_holder() {
    difference() {
        clone_mirror([0,1,0]) translate([114,38.5,-10]) cube([60,51,23], center=true);  
        clone_mirror([0,1,0]) translate([90,38.5,-19.5]) cube([20,55,10], center=true);  
        engines();
        engine_holder_holder();
    }
}

module conectors() {
    difference() {
        union() {
            minkowski() {           
                clone_mirror([0,1,0]) {
                    translate([-60,72.5,-32.5]) cube([200,10,10], center=true);    
                    translate([-40,82.5,40]) difference() {
                        cube([35,3,16], center=true);
                        translate([0,0,-5]) cube([20,5,10], center=true);
                    }
                    translate([-40,30,-40]) difference() {
                        cube([35,5,16], center=true);
                        translate([0,0,5]) cube([20,10,10], center=true);
                    }     
                }   
                sphere(2.5);
            }
        }
        wheels_cutoff();
        acumulator();        
        back_wheels(true);
    }
}


module camera_cutoff_for_main() {
    translate([60,0,52]) {
        minkowski() {
            difference() {
                cube([30,155,10], center=true);
                cube([30,90,11], center=true);
            }
            sphere(3);
        }
    }
}

module placed_camera_holder(servos=true) {
    translate([100,0,50]) {
        camera_holder(servos);
        translate([-40,0,2])
        minkowski() {
            difference() {
                cube([30,150,10], center=true);
                cube([30,90,11], center=true);
            }
            sphere(2);
        }
        clone_mirror([0,1,0]) 
            translate([-55,62.5,-35])
                cube([30,10,40]);
        
    }
}


module main() {  
    difference() {
        union() {
            
            // zewnętrzna część
            difference() {
                cube([320,170,100], center=true);
                translate([0,0,10]) cube([310,160,100], center=true);
            }
            clone_mirror([0,1,0]) translate([-50,30,-37.5]) cube([30,20,10], center=true);
            
            // błotniki
            intersection() {
                first_print_area();
                clone_mirror([0,1,0]) translate([60,85,-14.5]) rotate([90,0,0]) cylinder(12, 85, 85);
            }
            
            // uchwyt na tylny łącznik
            clone_mirror([0,1,0]) translate([-110,70,-30]) cube([100, 20, 30], center=true);
            
            // uchwyt akumulatora
            difference() {
                translate([0,0,-30]) cube([80,170,35], center=true);
                acumulator();
            }
            // uchwyt osi i kół
            clone_mirror([0,1,0]) translate([-20,64,-40]) cube([180,14,55]);
            translate([60,0,-15]) cube([45,33.5,50], center=true);
                    
            
            //uchwyt silników
            clone_mirror([0,1,0]) translate([114,40,-30]) {
                cube([60,55,20], center=true);
                translate([40,-5,-5]) cube([50,10,10], center=true);
                translate([40,15,-5]) cube([50,10,10], center=true);
            }
            translate([120,0,-30]) cube([80,33.5,30], center=true);   
            translate([100,0,0]) cube([40,15,40], center=true);          
            clone_mirror([0,1,0]) translate([86,40,-19.5]) cube([5,55,10], center=true); 
            
            
            // uchwyt komputera
            difference() {
                translate([0,-30,-35.01]) union() {
                    translate([-83, -8, -4]) cube([10,10,10], center=true);
                    translate([-137, -8, -4]) cube([10,10,10], center=true);
                    translate([-83, 70, -4]) cube([10,10,10], center=true);
                    translate([-137, 70, -4]) cube([10,10,10], center=true);
                }
                computer();
            }
        }                
        translate(forward_axis_vector) rotate([90,0,0]) cylinder(200,14,14,center=true);
        engine_holder();
        engines();
        acumulator();
        conectors();
        bearings(1);
        wheels_cutoff();        
        engine_holder_holder();          
        distance_sensors();
        side_distance_meters(false);        
        power_supply();
        back_wheels(true);
        camera_cutoff_for_main();       
        translate([170,0,42]) rotate([0,60,0]) cube([50,220,50], center=true);
    }
}

module main_first() {
    intersection() {
        main();
        first_print_area();
    }
}

module main_second() {
    intersection() {
        main();
        second_print_area();
    }
}

module side_distance_meters_on_proper_height(with_holes=true) {
    translate([140,90,-19.7]) rotate([0,0,90]) side_distance_meter(with_holes);
}

module side_distance_meters(with_holes=true) {
    clone_mirror([0,1,0]) {
        side_distance_meters_on_proper_height(with_holes);
        translate([-165,0,0]) side_distance_meters_on_proper_height(with_holes);
        translate([-290,0,0]) side_distance_meters_on_proper_height(with_holes);
        translate([-230,0,0]) side_distance_meters_on_proper_height(with_holes);
    }
}

module power_supply() {
    translate([100,0,-47.5]) {
        mirror([0,0,1]) {
            cylinder(1.5, 41.5, 41.5);
            cylinder(2.51, 38, 38);
        }
        translate([-39,0,-10]) cylinder(100,2.5,2.5);
    }
}

module back_wheels(srews=false) {
    clone_mirror([0,1,0]) {
        translate([-125,60,-51]) {
            if (srews)
                back_wheel_srew_holes();
            else
                back_wheel();
        }
    }
}

module body_camera_cutoff() {
    translate([100,0,0]) scale([1,1.25,1]) {
        cylinder(200,40,40);
        clone_mirror([0,1,0]) cube([40,40,200]);
    }
}

module speaker() {
    cylinder(21,77/2,77/2);
}

module speakers_holders() {
  clone_mirror([0,1,0]) translate([-80,41,51]) difference() {
    cylinder(21,42,42);
    speaker();
  }
}

module speaker_holes() {
    clone_mirror([0,1,0]) translate([-80,41,51]) {
        for (i=[1:51])
            rotate([0,0,48*i]) translate([i/2+10,0,0]) cylinder(100, 2, 2);
    }
}

module body() {
    difference() {
        clone_mirror([0,1,0]) {                        
            difference() {
                translate([60,0,-14.5]) rotate([-90,0,0]) difference() {
                    cylinder(90, 87, 87);
                    cylinder(90, 85, 85);
                }            
                translate([0,0,-50]) cube([320,240,200], center=true);
            }
            translate([110,0,50]) cube([30,90,2]);
            
            translate([-160,0,70]) cube([220,90,2]);
            
            translate([-160,0,50]) difference() {
                cube([220,85,22]);
                translate([5,0,0]) cube([216,83,20]);
            }
            translate([-155,30,40]) cube([5,30,30]);
            translate([-130,74.5,40]) cube([30,5,30]);
            translate([-60,74.5,40]) cube([30,5,30]);
            translate([-40,30,50]) cube([10,50,20]);
            
            translate([150,0,30]) rotate([0,60,0]) cube([50,180,2], center=true);
            
            speakers_holders();
        }
        body_camera_cutoff();
        speaker_holes();
        clone_mirror([0,1,0]) translate([60,0,-14.5]) rotate([-90,0,0]) cylinder(90, 85, 85); 
        translate([-30,70,0]) cube([31,12,100]);
    }
    
}

module board_holder() {
    clone_mirror([0,1,0]) {
        translate([-160,70,8]) cube([140,3,6]);  
        translate([-40,75-0.5,-15+2.5]) cube([10,5,25]);     
        translate([-70,75-0.5,-15]) cube([10,5,25]); 
        translate([-100,75-0.5,-15]) cube([10,5,25]);
        translate([-135,75-0.5,-15]) cube([10,5,25]);
        translate([-155,70,-15]) cube([10,5,30]);
        translate([-130,0,10]) difference() {
            translate([-5,0,0]) cube([98,80-0.5,8]);
            translate([-2,0,4]) cube([90,150/2,4]);
            translate([0,0,-1]) cube([90-4,150/2-2,10]);
        }
    }
    
}


module speed_sensor_holder() {
    clone_mirror([0,1,0]) {
        difference() {
            translate([50,17,4]) cube([20,15,11]);
            translate([56.25,17,9]) cube([5.75,13,15]);
            translate([56,17,-3]) difference() {
                cube([6.5,12,12]);
                translate([-0.25,4.3,-3]) cube([7,3,11]);
            }
        }
        translate([50,0,10]) cube([5,18,5]);
        translate([65,0,10]) cube([5,18,5]);
        
        translate([35,7.5,10]) cube([50,10,5]);        
        translate([35,0,-5]) cube([2.5,17,15]);
        
        translate([35,0,10]) cube([20,10,5]);
        translate([65,0,10]) cube([15,10,5]);
    }
}


module bumper_connection(a=7, b=3, h=15) {
    difference() {
        cube([h,a,a]);
        translate([0,(a-b)/2,a-b]) cube([h,b,b]);
    }
}


module bumper_part(l, d=4, w=10) {
    difference() {
        cube([w,l,35]);
        translate([0, 0, d]) cube([w-d,l,35-d*2]);
    }
}

module bumper_sensor_holes() {
    clone_mirror([0,1,0]) {
        translate([142,92,-45]) distance_sensor();
        translate([167,30,-45]) distance_sensor();
        translate([-30,92,-45]) distance_sensor();
        translate([-90,92,-45]) distance_sensor();
        translate([-163,92,-45]) distance_sensor();
        translate([-163,30,-45]) distance_sensor();
        
        translate([172,92,-30]) rotate([0,90,0]) distance_sensor();
        translate([172,30,-30]) rotate([0,90,0]) distance_sensor();
        translate([-165,30,-30]) rotate([0,90,0]) distance_sensor();
        translate([-165,92,-30]) rotate([0,90,0]) distance_sensor();
        
        translate([142,95,-30]) rotate([90,0,0]) distance_sensor();
        //translate([-30,95,-30]) rotate([90,0,0]) distance_sensor();
        //translate([-90,95,-30]) rotate([90,0,0]) distance_sensor();
        translate([-163,95,-30]) rotate([90,0,0]) distance_sensor();
    }
}


module bumper_cutoff(d=1) {    
    clone_mirror([0,1,0]) {
        cube([d,200,40]);
        translate([-10,0,40]) cube([10+d,200,d]);
        translate([-10,0,50]) cube([10+d,200,d]);
        translate([-10,0,40]) cube([d,200,10]);
        translate([0,0,50]) cube([d,200,40]);
    }
}

module bumper() {
    difference() {
        union() {
            difference() {
                clone_mirror([0,1,0]) {
                    translate([160,0,-50]) bumper_part(100,4,15);
                    translate([175,85,-50]) rotate([0,0,90]) bumper_part(40, 4, 15);
                    
                    translate([-20,85,-50]) rotate([0,0,90]) bumper_part(150, 4, 15);
                    translate([-156,100,-50]) rotate([0,0,180]) bumper_part(100, 4, 15);
                    
                    translate([155,71.5,-43.5]) bumper_connection(7,3,20);
                    translate([135.5,75,-24.25]) rotate([0,90,0]) rotate([0,0,90]) bumper_connection(9, 4, 20);
                        
                    translate([-30,75,-24.25]) rotate([0,90,0]) rotate([0,0,90]) bumper_connection(9, 4, 20);
                    translate([-95,75,-24.25]) rotate([0,90,0]) rotate([0,0,90]) bumper_connection(9, 4, 20);
                    translate([-155,75,-24.25]) rotate([0,90,0]) rotate([0,0,90]) bumper_connection(9, 4, 20);
                    
                    translate([-170,78.5,-6.5]) rotate([180,0,0]) bumper_connection(7,5,20);
                    translate([-172,51.5,-33.5]) bumper_connection(7,3,22);
                    translate([-170,78.5,-15]) rotate([0,270,0]) rotate([180,0,0]) bumper_connection(7,5,5);
                }
                if (!$preview)
                    main();
            }
            clone_mirror([0,1,0]) translate([171,0,-50]) cube([4,100,35]);
        }
        bumper_sensor_holes();
        translate([-140,0,-77.5]) bumper_cutoff(0.1);
    }
    
}


module charger() {
    translate([200,0,-60]) {
        difference() {
            translate([0,0,5]) cube([50,170,40], center=true);
            cube([45,160,35], center=true);
            translate([-20,0,-7]) cube([20,90,20], center=true);
            translate([21,-80,-10]) cube(5);
        }
        translate([-100,0,-5]) difference() {
             cube([150,100,20], center=true);
             translate([5,0,-2]) cube([150,95,20], center=true);
        }
    }
}


module print(mode=0) {
    
    if (mode==-1) for (i=[1:50]) translate([0, 300*i, 0]) print(i);
    if (mode==0) for (i=[1:50]) print(i);
        
    if (mode==1) main_first();
    if (mode==2) main_second();
    if (mode==3) color("lightgray") spindles_gears();
    if (mode==4) color("lightgray") engine_gears();
    if (mode==5) color("pink", 0.7) engine_holder();
    if (mode==6) color("darkgray") bearings();
    if (mode==7) color("pink") conectors();
    if (mode==8) color("lightgray") wheels();
    if (mode==9) color("blue") tires();
    if (mode==11) color("gray") spindles();
    if (mode==12) color("pink") engine_holder_holder();
    if (mode==13) color("gray") speedometer();
    if (mode==14) color("brown") spindles_pins(true);
    ////if (mode==15) color("darkgray") side_distance_meters();
    if (mode==16) color("gray") spindles_distances();
    if (mode==17) placed_camera_holder(false);
    if (mode==18) color("green") board_holder();
    if (mode==19) color("lightblue") speed_sensor_holder();
    if (mode==20) color("darkgray") bumper();
        
    if (mode==21) color("lightblue") intersection() {first_print_area(); body();}
    if (mode==22) color("lightblue") intersection() {second_print_area(); body();}
    
    if (mode==23) charger();
}


//$fn = 50;
print(0);


if ($preview) {
    //first_print_area();
    //second_print_area();
    
    back_wheels();
}


