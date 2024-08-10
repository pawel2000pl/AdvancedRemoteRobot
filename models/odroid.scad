// Hard Kernel Odroid XU4 Model by hominoid @ www.forum.odroid.com
//
// Public Domain Version 1.0  odroid_xu4, heatsink_stock, heatsink_gold,
//                            heatsink_northbridge, heatsink_plate, heatsink_adapter
//               Version 1.1  added rtc_holder, uart_holder,uart_strap, fan_iso_pin, fan
//               Version 1.1a adjusted battery holder size 10.9
//               Version 1.1b re-adjusted battery holder size 10.9 to 10.2mm
//                            increase fan size from 10mm to 12mm
//               Version 1.1c added embedded M3 nut option to HS slides
//                            added heatsink_plate_gold()
//                            added heatsink_adapter_gold()
//                            added heatsink_spacer() 1mm spacers for heatsink case back hold down system
//               Version 1.1d adjusted heastsink_gold () position
//                            adjusted haetsink_plate_gold() and heatsink_adapter_gold()
//                            raised all heatsinks 1mm to correct height
// USE:
// odroid_xu4 (HEATSINK_TYPE)
//                   0 = no heatsink
//                   1 = stock blue heatsink
//                   2 = gold heatsink
//                   3 = typical northbridge 40x40x25mm
//                   4 = 40mm plate
// heatsink_stock()
// heatsink_gold()
// heatsink_northbridge()
// heatsink_plate()
// heatsink_plate_gold()
// heatsink_adapter(NUT) 0 = No Nut Holder 1 = Nut Holder
// heatsink_adapter_gold(NUT) 0 = No Nut Holder 1 = Nut Holder
// heatsink_spacer() 1mm
// batt_holder(TAB)   0 = No Tabs 1 = Tabs
// uart_holder(TAB)  0 = No Tabs 1 = Tabs
// uart_strap()
// fan_iso_pin()
// fan()

module odroid_xu4(HEATSINK_TYPE) {

    length=83;
    width=59;
    NUT=1;
    $fn=25;
    
    // pcb
    difference() {
        color("tan") pcb([length,width,1], 3);
        // pcb mounting holes
        translate ([3.5,3.5,-1]) cylinder(r=1.5, h=3);
        translate ([length-3.5,3.5,-1]) cylinder(r=1.5, h=3);
        translate ([length-3.5,width-3.5,-1]) cylinder(r=1.5, h=3);
        translate ([3.5,width-3.5,-1]) cylinder(r=1.5, h=3);
        // heatsink mounting holes
        translate ([79.61,22,-1]) cylinder(r=1.5, h=3);
        translate ([28.39,42,-1]) cylinder(r=1.5, h=3);
    }
    
    // ethernet port
    difference () {
        color("lightgrey") translate([15.40,(21.5/2),(13.5/2)+1]) cube([16, 21.5, 13.5], true);
        color("darkgrey") translate([15.40,(21.5/2)-2,(13.5/2)]) cube([13, 19.5, 8], true);
        color("darkgrey") translate([15.40,-2,11]) cube([5, 19.5, 5], true);
    }
    color("green") translate([9.60,-.1,11.5]) cube([2, 2, 2]);
    color("orange") translate([19.40,-.1,11.5]) cube([2, 2, 2]);
    
    // usb 2.0 port
    difference () {
        color("silver") translate([28.78,(19.5/2),(14/2)+1]) cube([5.75, 19.5, 14], true);
        color("lightgrey") translate([28.78,(12.5/2)-1,(13/2)+1.25]) cube([4.75, 12.5, 13],true);
    }
    color("white") translate([27.78,(17.5/2)+.5,(11/2)+2]) cube([2, 17.5, 11],true);
    
    // power plug
    difference () {
        color("silver") translate([38.5,-.75+(11/2),(10/2)+1]) cube([7.75, 11, 10],true);
        color("darkgrey") translate([38.5,10,(10/2)+2]) rotate([90,0,0]) cylinder(r=2.75, h=11);
    }
    color("white") translate([38.5,10,(10/2)+2]) rotate([90,0,0]) cylinder(r=1, h=11);
    
    // micro sdcard
    difference () {
        color("silver") translate([51.5, (5.5/2)+4.5, (3.5/2)+1]) cube([12, 5.5, 3.5],true);
        color("darkgrey") translate([51.5, 5.5/2, (3.5/2)+2]) cube([11, 5.5, 1],true);
    }
    
    // hdmi
    difference () {
        color("silver") translate([67.5, (12/2)-1, (6.5/2)+1]) cube([15, 12, 6.5],true);
        color("darkgrey") translate([67.5, (11/2)-2, (5.5/2)+1.5]) cube([14, 11, 5.5],true);
    }
    
    // boot select switch
    color("silver") translate([83-3.75, 8, 1]) cube([3.75, 9.25, 3.5]);
    color("white") translate([83, 14, 2]) cube([3, 2, 1.5]);

    // i2s port
    difference () {
        color("black") translate([((78.94-1.25)+(5.5/2)-1.25), 42, (6.25/2)+1]) cube([5.5, 19.5, 6.25],true);
        color ("darkgrey") translate ([((78.94-1)+(5/2)-1.25), 42, (5.75/2)+2]) cube([5, 19, 5.75],true);
    }

    // gpio port
    difference () {
        color("black") translate([53.9, ((54.5-1)+(5.5/2))-1.25, (6.25/2)+1]) cube([37, 5.5, 6.25], true);
        color ("darkgrey") translate ([53.9, ((54.5-.75)+(5/2))-1.25, (5.75/2)+2]) cube([36.5, 5, 5.75],true);
    }
    
    // power button
    color("silver") translate([28.93, 55.92, (4/2)+1]) cube([6,6,4], true);
    color("black") translate([28.93, 55.92, (4/2)+1]) cylinder(r=1.6, h=13.5);

    // usb 3.0 ports
    difference () {
        color("silver") translate([15.15,59-(17.5/2),(15.5/2)+1]) cube([13.25, 17.5, 15.5],true);
        color("darkgrey") translate([15.15,(59-(15.5/2))+2,(13.5/2)+2]) cube([11.25, 15.5, 13.5],true);
    }
    color("silver") translate([15.15,59-(17.5/2),(15.5/2)+1]) cube([13.25, 17.5, 2],true);
    color("royalblue") translate([15.15,59-(17.5/2)+2,(15.5/2)+6]) cube([10, 12.5, 1.5],true);
    color("royalblue") translate([15.15,59-(17.5/2)+2,(15.5/2)-2]) cube([10, 12.5, 1.5],true);
    
    // uart plug
    difference () {
        color("white") translate([.5, 38,1]) cube([5, 12.5, 6]);
        color("white") translate([1, 38.5,3]) cube([4, 11.5, 6]);
    }
    
    // rtc plug
    difference () {
        color("white") translate([0.5, 25.5,1]) cube([3.75, 7.5, 4.75]);
        color("white") translate([1, 26,3]) cube([2.75, 6.5, 4.75]);
    }
    
    // fan plug
    difference () {
        color("white") translate([27, 21,1]) cube([3.75, 7.5, 4.75]);
        color("white") translate([27.5, 21.5,3]) cube([2.75, 6.5, 4.75]);
    }
    
    // emmc
    color("darkred") translate([45, 0, -1.8]) cube([13.5, 18.67, 1.8]);
    color("dimgray") translate([46, 2, -2.63]) cube([11.5, 13, 2.63]);
    
    // soc
    color("dimgray") translate([(83-14.5)-9, 20, 1]) cube([14.5, 15.75, 1]);
    // pmic
    color("dimgray") translate([(83-5.75)-33.5, 27, 1]) cube([5.75, 5.75, .7]);
    // usb
    color("dimgray") translate([(83-7)-44, 40, 1]) cube([7, 7, .8]);
    // ethernet
    color("dimgray") translate([(83-6)-67, 23, 1]) cube([6, 6, .8]);
    
    // fan + heatsink
    if (HEATSINK_TYPE == 1) {
       color ("mediumturquoise",.5) translate ([74.61,12,2]) rotate([0,0,90]) heatsink_stock();
        }
    if (HEATSINK_TYPE == 2) {
        color ("gold",.5) translate ([74.61,12,2]) rotate([0,0,90]) heatsink_gold();
        color ("black",.5) translate ([74.61,11,4]) rotate([0,0,90]) heatsink_adapter_gold(NUT);
        }
    if (HEATSINK_TYPE == 3) {
        color ("silver",.6) translate ([74.61,12,2]) rotate([0,0,90]) heatsink_northbridge();
        }  
    if (HEATSINK_TYPE == 4) {
        color ("lightgrey",.6) translate ([74.61,12,2]) rotate([0,0,90]) heatsink_plate();
        }
}

module pcb(size, radius) {
    x = size[0];
	y = size[1];
	z = size[2];   
    linear_extrude(height=z)
	hull() {
		translate([0+radius ,0+radius, 0]) circle(r=radius);	
		translate([0+radius, y-radius, 0]) circle(r=radius);	
		translate([x-radius, y-radius, 0]) circle(r=radius);	
		translate([x-radius, 0+radius, 0]) circle(r=radius);
	}  
}

module heatsink_stock () {
    difference (){ 
        translate ([6.5,-5,0]) cube([7,5,2]);
        translate ([10,-5,-1]) cylinder(r=1.375, h=4);
    }
    difference (){ 
        translate ([26.5,40,0]) cube([7,5,2]);
        translate ([30,45,-1]) cylinder(r=1.375, h=4);
    }
    difference () {
        translate ([10,-5,0]) cylinder(r=3.5, h=2);
        translate ([10,-5,-1]) cylinder(r=1.375, h=4);
    }
    difference () {
        translate ([30,45,0]) cylinder(r=3.5, h=2);
        translate ([30,45,-1]) cylinder(r=1.375, h=4);
    }
    difference() {
        cube([40, 40, 13.5]);
        for (y=[1.5:2:38.5]) {
                translate([-1,y,2]) cube ([42,1,12]);
                }
        translate([20,20,2]) cylinder(r=18, h=13.5, $fn=100);
        }
 }
 
 module heatsink_gold () {
    difference() {
        cube([38, 40, 36.25]);
        // universal slots
        translate([-1,0,2]) heatsink_slot();
        // fins       
        for (y=[5:3.7:31.7]) {
            translate([y,-1,9.5]) cube ([1.85,48,28]);
            }          
        for (y=[6:6.65:38]) {
            translate([-5,y,9.5]) cube([48,1.85,28]);
            }     
        translate([(8.7-1.90),-1,34]) cube([2,42,4]);       
        translate([(12.4-1.90),-1,32]) cube([2,42,5]);      
        translate([(16.1-1.90),-1,30]) cube([2,42,7]);          
        translate([(19.8-1.87),-1,32]) cube([2,42,7]);       
        translate([(19.9+1.70),-1,30]) cube([2,42,7]);        
        translate([(23.6+1.70),-1,32]) cube([2,42,5]);        
        translate([(27.3+1.70),-1,34]) cube([2,42,4]);       
        translate([.3,-1,28]) cube([3,42,10]);
        translate([34.7,-1,28]) cube([3,42,10]);        
        translate([31,-1,35.25]) cube([10,42,10]);
        translate([-1,-1,35.25]) cube([10,42,10]); 
        }
    difference () {
        translate([-2,0,23.75]) cube([2,40,12.5]);
        for (y=[6:6.65:38]) {
            translate([-5,y,9.5]) cube([48,1.85,28]);
            }
        }
    difference () {
        translate([38,0,23.75]) cube([2,40,12.5]);       
        for (y=[6:6.65:38]) {
            translate([-5,y,9.5]) cube([48,1.85,28]);
            }
        }
    difference () {
        translate([1,40,23.75]) rotate([90,0,0]) cylinder(r=3,h=40,$fn=25); 
        for (y=[6:6.65:38]) {
            translate([-5,y,9.5]) cube([48,1.85,28]);
            }
        }
    difference () {
        translate([37,40,23.75]) rotate([90,0,0]) cylinder(r=3,h=40,$fn=25);
        for (y=[6:6.65:38]) {
            translate([-5,y,9.5]) cube([48,1.85,28]);
            }
        }
 }
 
 module heatsink_northbridge () {
    difference (){ 
        translate ([6.5,-5,0]) cube([7,5,2]);
        translate ([10,-5,-1]) cylinder(r=1.375, h=4);
        }
    difference (){ 
        translate ([26.5,40,0]) cube([7,5,2]);
        translate ([30,45,-1]) cylinder(r=1.375, h=4);
    }
    difference () {
        translate ([10,-5,0]) cylinder(r=3.5, h=2);
        translate ([10,-5,-1]) cylinder(r=1.375, h=4);
    }
    difference () {
        translate ([30,45,0]) cylinder(r=3.5, h=2);
        translate ([30,45,-1]) cylinder(r=1.375, h=4);
    }
    difference() {
        cube([40, 40, 25]);
        for (y=[1.5:2:38.5]) {
            translate([y,-1,2]) cube ([1,42,25]);
            }
        difference () {
            translate([40,40,25]);
            for (y=[4:6:40]) {
                translate([-1,y,2]) cube([42,2,23]);
                }
        }
    }
 }
  module heatsink_plate() {
    cube ([40,40,2]);
    difference (){ 
        translate ([6.5,-5,0]) cube([7,5,2]);
        translate ([10,-5,-1]) cylinder(r=1.375, h=4, $fn=25);
        }
    difference (){ 
        translate ([26.5,40,0]) cube([7,5,2]);
        translate ([30,45,-1]) cylinder(r=1.375, h=4, $fn=25);
    }
    difference () {
        translate ([10,-5,0]) cylinder(r=3.5, h=2);
        translate ([10,-5,-1]) cylinder(r=1.375, h=4, $fn=25);
    }
    difference () {
        translate ([30,45,0]) cylinder(r=3.5, h=2);
        translate ([30,45,-1]) cylinder(r=1.375, h=4, $fn=25);
    }
}

module heatsink_adapter(NUT) {
    difference () {
        heatsink_plate ();
        translate ([0,-.1,1.7]) cube ([40,40.2,.4]);             
        translate ([-1,-1,-1]) cube ([3,42,4]);
        translate ([38,-1,-1]) cube ([3,42,4]);       
        translate ([9.65,-.1,-1]) cube ([20.7,40.2,5]);
        }
    difference () {
        translate ([5.65,0,1.7]) cube ([4,40,1.3]);
        translate ([9.10,-.1,1.7]) cube ([2,40.2,1.31]);
    }
    difference () {
        translate ([30.35,0,1.7]) cube ([4,40,1.3]);
        translate ([30.349,-.1,1.7]) cube ([.501,40.2,1.31]);
    }   
    translate ([2,-4,0]) cube ([6,4,1.7]);
    translate ([32.75,40,0]) cube ([5.25,4,1.7]);   
    translate ([5.65,-1,.3]) rotate ([45,0,0]) cube ([3.45,2.6,1.3]);
    translate ([30.85,39,2.08]) rotate ([-45,0,0]) cube ([3.5,2.6,1.3]);
    if ( NUT == 1 ) {
        difference (){
            translate ([10,-5,0]) 
            cylinder(r1=4, r2=4.75, h=4.5,$fn=60);
            translate ([10,-5,-1])
            cylinder (r=1.375, h=5,$fn=60);
            translate ([10,-5,2])
            cylinder(r=3.35,h=5,$fn=6);
            
        }
            difference (){
            translate ([30,45,0]) 
            cylinder(r1=4,r2=4.75,h=4.5,$fn=60);
            translate ([30,45,-1])
            cylinder (r=1.375,h=5,$fn=60);
            translate ([30,45,2])
            cylinder(r=3.35,h=5,$fn=6);
            
        }
    }
}

 module heatsink_plate_gold() {
    cube ([40,40,2]);
    difference (){ 
        translate ([2,-5,0]) cube([13.5,5,2]);
        translate ([11,-5,-1]) cylinder(r=1.375, h=4, $fn=25);
        }
    difference (){ 
        translate ([24.5,40,0]) cube([13.5,5,2]);
        translate ([29,45,-1]) cylinder(r=1.375, h=4, $fn=25);
    }
    difference () {
        translate ([11,-5,0]) cylinder(r=3.5, h=2);
        translate ([11,-5,-1]) cylinder(r=1.375, h=4, $fn=25);
    }
    difference () {
        translate ([29,45,0]) cylinder(r=3.5, h=2);
        translate ([29,45,-1]) cylinder(r=1.375, h=4, $fn=25);
    }
}

module heatsink_adapter_gold(NUT) {
    difference () {
        heatsink_plate_gold ();
        translate ([0,0,1.7]) cube ([40,40,.3]);
        translate ([9.65,0,-1]) cube ([20.7,40,5]);
        translate ([0,0,-1]) cube ([2,40,4]);
        translate ([38,0,-1]) cube ([2,40,4]);
        }
    difference () {
        translate ([5.65,0,1.7]) cube ([4,40,1.3]);
        translate ([9.10,0,1.7]) cube ([2,40,1.3]);
    }
    difference () {
        translate ([30.35,0,1.7]) cube ([4,40,1.3]);
        translate ([30.35,0,1.7]) cube ([.5,40,1.3]);
    }
    
    translate ([2,-4,0]) cube ([6,4,1.7]);
    translate ([32.75,40,0]) cube ([5.25,4,1.7]);    
    translate ([5.65,-1,.3]) rotate ([45,0,0]) cube ([3.45,2.6,1.3]);
    translate ([30.85,39,2.08]) rotate ([-45,0,0]) cube ([3.5,2.6,1.3]);
    if ( NUT == 1 ) {
        difference (){
            translate ([11,-5,0]) 
            cylinder(r1=4, r2=4.75, h=4.5,$fn=60);
            translate ([11,-5,-1])
            cylinder (r=1.375, h=5,$fn=60);
            translate ([11,-5,2])
            cylinder(r=3.35,h=5,$fn=6);
            
        }
            difference (){
            translate ([29,45,0]) 
            cylinder(r1=4,r2=4.75,h=4.5,$fn=60);
            translate ([29,45,-1])
            cylinder (r=1.375,h=5,$fn=60);
            translate ([29,45,2])
            cylinder(r=3.35,h=5,$fn=6);
            
        }
    }
}

module heatsink_slot() {
    difference () {
        translate([-0,-1,0]) cube([40,42,2]);
        translate ([0,-1,1.7]) cube ([40,42,.3]);             
        translate ([9.65,-2,-1]) cube ([20.7,44,5]);
        }
    difference () {
        translate ([5.65,-1,1.7]) cube ([4,42,1.3]);
        translate ([9.10,-1,1.7]) cube ([2,42,1.3]);
    }
    difference () {
        translate ([30.35,-1,1.7]) cube ([4,42,1.3]);
        translate ([30.35,-1,1.7]) cube ([.5,42,1.3]);
    }
}

module heatsink_spacer() {
    difference () {
        translate ([0,0,0]) cube ([8,8,1]);
        translate ([1.5,1.5,-1]) cube ([5,5,3]);
    }
        difference () {
        translate ([15,0,0]) cube ([8,8,1.05]);
        translate ([16.5,1.5,-1])cube ([5,5,3]);
    }    difference () {
        translate ([0,15,0]) cube ([8,8,1]);
        translate ([1.5,16.5,-1]) cube ([5,5,3]);
    }
        difference () {
        translate ([15,15,0]) cube ([8,8,1.05]);
        translate ([16.5,16.5,-1])cube ([5,5,3]);
    }
}

module batt_holder(TAB) {
    // rtc battery holder
    difference () {
        cylinder(r=12.75,h=6,$fn=360);
        translate ([0,0,-1]) cylinder(r=10.2,h=8,$fn=360);
        cube([14,26,13], true);
    }
    cylinder(r=12.75, h=2);
    if ( TAB == 1 ) {
        //external mounting tabs
        difference (){ 
            rotate ([0,0,90]) translate ([-3.5,-16,0]) cube([7,5,3]);
            rotate ([0,0,90]) translate ([0,-16,-1]) cylinder(r=1.375, h=4, $fn=60);
        }
        difference () {
            rotate ([0,0,90]) translate ([0,-16,0]) cylinder(r=3.5, h=3, $fn=60);
            rotate ([0,0,90]) translate ([0,-16,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
        
        difference (){ 
            rotate ([0,0,90]) translate ([-3.5,11,0]) cube([7,5,3]);
            rotate ([0,0,90]) translate ([0,16,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
        difference () {
            rotate ([0,0,90]) translate ([0,16,0]) cylinder(r=3.5, h=3, $fn=60);
            rotate ([0,0,90]) translate ([0,16,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
    }
}

module uart_holder(TAB) {
    // micro usb uart module holder
    difference () {
        translate ([0,0,0]) cube([18,24,9]);
        translate ([2,-2,3]) cube([14,27,7]);
        //pin slot
        translate ([3.5,7,-1]) cube([11,1,5]);
        //component bed
        translate ([3.5,8.5,2]) cube([11,14,2]);
        //side trim
        translate ([-1,7,6]) cube([20,18,4]);
    }    
    difference (){
        translate ([-1.5,4,0]) cylinder(r=3,h=9, $fn=60);
        translate ([-1.5,4,-1]) cylinder (r=1.375, h=11, $fn=60);
    }    
    difference (){
        translate ([19.5,4,0]) cylinder(r=3,h=9, $fn=60);
        translate ([19.5,4,-1]) cylinder (r=1.375, h=11,$fn=60);
    }
    if ( TAB == 1 ) {
        //external mounting tabs
        difference (){ 
            rotate ([0,0,90]) translate ([10.5,-23,0]) cube([7,5,3]);
            rotate ([0,0,90]) translate ([14,-23,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
        difference () {
            rotate ([0,0,90]) translate ([14,-23,0]) cylinder(r=3.5, h=3, $fn=60);
            rotate ([0,0,90]) translate ([14,-23,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
        
        difference (){ 
            rotate ([0,0,90]) translate ([10.5,0,0]) cube([7,5,3]);
            rotate ([0,0,90]) translate ([14,5,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
        difference () {
            rotate ([0,0,90]) translate ([14,5,0]) cylinder(r=3.5, h=3, $fn=60);
            rotate ([0,0,90]) translate ([14,5,-1]) cylinder(r=1.375, h=5, $fn=60);
        }
    }  
}

module uart_strap () { 
    difference () {
        translate ([-4.5,1,9]) cube([27,6,3]);
        translate ([-1.5,4,8]) cylinder (r=1.6, h=5, $fn=60);
        translate ([19.5,4,8]) cylinder (r=1.6, h=5, $fn=60);
    }   
    difference (){
        translate ([-1.5,4,12]) cylinder(r=3,h=1, $fn=60);
        translate ([-1.5,4,11]) cylinder (r=1.6, h=7, $fn=60);
    }  
    difference (){
        translate ([19.5,4,12]) cylinder(r=3,h=1, $fn=60);
        translate ([19.5,4,11]) cylinder (r=1.6, h=7, $fn=60);
    }    
}

module fan() {    
        difference() {
            cube([40, 40, 12], false);
            translate([20,20,-1]) cylinder(r=19, 14,$fn=360);
            translate([4,4,-1]) cylinder(r=1.75, 14,$fn=60);
            translate([36,4,-1]) cylinder(r=1.75, 14,$fn=60);
            translate([4,36,-1]) cylinder(r=1.75, 14,$fn=60);
            translate([36,36,-1]) cylinder(r=1.75, 14,$fn=60);    
        }   
}

module fan_iso_pin () {
    cylinder(2, 5, 5, $fn=60);
    translate ([0, 0, 2]) cylinder(9, 2.0625, 2.0625, $fn=60);
    translate ([0, 0, 4]) cylinder(1.25, 2.625, 2.625, $fn=60);
    translate ([0, 0, 9]) cylinder(7, 2.625, 1.5, $fn=60);
    translate ([0, 0, 16]) cylinder(8, 1.5, 1.5, $fn=60);
    translate ([0, 0, 24]) sphere(d=3.75, $fn=60);
}