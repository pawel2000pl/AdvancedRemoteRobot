module copy_mirror(axis) {
    union() {
        children();
        mirror(axis)
        children();
    }
}

// promień, wypełnienie, wysokość rolki, szerokość szyny, wysokość szyny
module roll(ray=0.5, liner=0.5, height=1, railWidth=0.15, railHeight=0.15, epsilon=0) {
    
    wallThickness = ray * liner;
    rayZero = ray - wallThickness;    
    rayZeroOnRails = max(0, rayZero - railHeight);
    delta45 = (railHeight>0) ? (rayZero - rayZeroOnRails) / (railHeight) * (railWidth / 2 + epsilon) / 2 : 0;
    
    copy_mirror([0,0,1])
    rotate_extrude() {
        polygon([
            [ray - railHeight, 0],
            [ray, railWidth/2 + epsilon],
            [ray, height/2 - epsilon],
            [rayZero, height/2 - epsilon],
            [rayZero, railWidth/2 + wallThickness + delta45],
            [rayZeroOnRails, railWidth/2 + wallThickness - delta45],
            [rayZeroOnRails, 0]    
        ]);
    } 
}

// promień wewnętrzny, promień zewnętrznt, wysokość
module innerRing(r1=1, r2=1.1, height=1, coverSize=0.15, coverThickness=0.1, railWidth=0.15, railHeight=0.15) {
    
    copy_mirror([0,0,1])
    rotate_extrude() {
        polygon([
            [r1, 0],
            [r1, height/2],
            [r2 + coverSize, height/2],
            [r2 + coverSize, height/2 - coverThickness],
            [r2, height/2 - coverThickness],
            [r2, railWidth/2],
            [r2 + railHeight, 0],
            [r2 + railHeight, 0],
            [r2, 0]
        ]);
    }
}

// promień wewnętrzny, promień zewnętrznt, wysokość
module outerRing(r1=2.8, r2=3, height=1, coverSize=0.15, coverThickness=0.1, railWidth=0.15, railHeight=0.15) {
        
    copy_mirror([0,0,1])
    rotate_extrude() {
        polygon([
            [r2, 0],
            [r2, height/2],
            [r1 - coverSize, height/2],
            [r1 - coverSize, height/2 - coverThickness],
            [r1, height/2 - coverThickness],
            [r1, railWidth/2],
            [r1 - railHeight, 0],
            [r1 - railHeight, 0],
            [r1, 0]
        ]);
    }
    
}


// Funkcja rekurencyjna do obliczenia rollRay
function calculateRollRay(destRay, ray, nroll, rayToRollCenter) = 
    ray > destRay ? calculateRollRay(destRay, rayToRollCenter * sin(180/(nroll+1)), nroll+1, rayToRollCenter) : [ray, nroll];


module drawStar(n, r) {
    for (i=[0:n-1]) {
        rotate([0, 0, i*360/n])
        translate([r, 0, 0])
        children();
    }
}


// promień wewnętrzny, proień zewnętrzny, minimalna grubość (bezwzględna), względny rozmiar zakrycia, względna grubość zakrycia, wględne wypełnienie rolek, szerokość szyny prowadzącej rolki, wysokość szyny prowadzącej rolki
module bearing(r1=5, r2=15, height=12, minThickness=1, coverRatio=0.1, coverThicknessRatio=0.0, rollLiner=0.5, railWidthRatio=0.3, railHeightRatio=0.1, epsilon_xy=0.01, epsilon_z=0.01) {
    
    rayToRollCenter = (r1 + r2) / 2;

    // Wywołanie funkcji rekurencyjnej
    rayAndCount = calculateRollRay((r2-r1)/2-minThickness-2*epsilon_xy, r2/2, 2, rayToRollCenter);
    rollRay = rayAndCount[0] - epsilon_xy/2;
    nroll = rayAndCount[1];
    
    railWidth = rollRay * railWidthRatio;
    railHeight = height * railHeightRatio;
    
    innerRing(
        r1, 
        rayToRollCenter-rollRay-epsilon_xy, 
        height, 
        coverRatio * rollRay, 
        height * coverThicknessRatio,
        railWidth, 
        railHeight
    );
    
    outerRing(
        rayToRollCenter+rollRay+epsilon_xy, 
        r2, 
        height, 
        coverRatio * rollRay, 
        height * coverThicknessRatio,
        railWidth, 
        railHeight
    );
    
    drawStar(nroll, rayToRollCenter)
    roll(
        rollRay, 
        rollLiner, 
        height - 2 * height * coverThicknessRatio, 
        railWidth, 
        railHeight, 
        epsilon_z
    );
}

//$fn = 64;
bearing();