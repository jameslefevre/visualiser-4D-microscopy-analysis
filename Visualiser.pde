public class Visualiser extends PApplet {

  PeasyCam cam;
  boolean sliceFlickerAlternator = true;

  boolean recording = false;
  boolean[] rotating = new boolean[3];
  boolean rotatingSpecial = false;
  int frameNum = 0;
  int sequenceTimer = 0;
  int sequenceTimerInit = 108;
  boolean shiftIsPressed = false;
  boolean manualResliceCurrentImage = false;
  boolean showNodeContactMetrics = false;


  public void settings() {
    size(800, 800, OPENGL); //P3D  OPENGL
    //size(1280, 1024, OPENGL);
  }
  public void setup() { 

    surface.setResizable(true);
    frameRate(10); // 10

    smooth();
    strokeWeight( 2 );
    ellipseMode( CENTER ); 
    lights();
    sphereDetail(5, 5);

    float[] dims = new float[]{dataset.voxelDim[0] * 581 * drawScalingFactor, dataset.voxelDim[1] * 736 * drawScalingFactor, dataset.voxelDim[2] * dataset.sliceCount * drawScalingFactor};

    //hint(ENABLE_STROKE_PERSPECTIVE);
    //float fov      = PI/3;  // field of view
    //float nearClip = 0.001;
    //float farClip  = 100000;
    //float aspect   = float(width)/float(height);  
    //perspective(fov, aspect, nearClip, farClip);  
    cam = new PeasyCam(this, -dims[0]/2, dims[1]/2, dims[2]/2, max(dims[0], dims[1], dims[2]));
    cam.setMinimumDistance(0);
    cam.setResetOnDoubleClick(false);
    //float fov = PI/3.0;
    // float cameraZ = (height/2.0) / tan(fov/2.0);
    //perspective(fov, float(width)/float(height), cameraZ/100.0, cameraZ*10.0); // default
  }

  public void draw() {
    sliceFlickerAlternator = !sliceFlickerAlternator;
    sequenceTimer = sequenceTimer > 0 ? sequenceTimer-1 : 0;
    // lights();
    // ambientLight(102, 102, 102);
    //ambientLight(255,255,255);
    //background(255);
    //    

    // implement any changes to visibility of each class in the segmentation images
    ArrayList<Integer> segColours = new ArrayList<Integer>(dataset.segmentationColours.keySet());
    for (int colorNum=0;colorNum<segColours.size();colorNum++) {
      boolean guiState = classesDisplayedCI.getState("col" + (colorNum+1));
      if (guiState != colClassesCIvisible.get(colorNum)) {
        colClassesCIvisible.put(colorNum, guiState);
        int col = segColours.get(colorNum);
        if (guiState) {
          col = color(red(col), green(col), blue(col), 0);
        }
        for (int imageNumber : dataset.timeSteps) {
          ImageData id = dataset.imageDatasetsByTimeStep.get(imageNumber); 
          id.changeColourAlphaClassifiedImages(col, (guiState ? 255 : 0));
        }
      }
    }
    
    // handling of reslicing of stack etc
    ImageData imData = dataset.imageDatasetsByTimeStep.get(dataset.timeSteps[currentImageNum]);
    if (showImage && imData!=null && imData.currentStack() != null){
      int currentSliceDim = imData.currentStack().dimRotate;
      int targetSliceDim = currentSliceDim;
  
      if (resliceMode_radio.getState("Auto")){
        float[] b = cam.getLookAt();
        float[] a = cam.getPosition();
        float x0 = abs(b[0]-a[0]);
        float x1 = abs(b[1]-a[1]);
        float x2 = abs(b[2]-a[2]);
        targetSliceDim = x2 > max(x1,x0) ? 0 : x1 > x0 ? 1 : 2;
      } else if (resliceMode_radio.getState("Fixed") || manualResliceCurrentImage){
        manualResliceCurrentImage=false;
        targetSliceDim = sliceAxis_radio.getState("X") ? 2 : sliceAxis_radio.getState("Y") ? 1 : sliceAxis_radio.getState("Z") ? 0 : targetSliceDim;
      }
  
      int dd =  targetSliceDim - currentSliceDim;
      if (dd==1 || dd==-2){
        println("reslicing, positive rotation of dimensions: from " + currentSliceDim + " to " + targetSliceDim);
        resliceCurrentImage(true);
      }
      if (dd==-1 || dd==2){
        println("reslicing, negative rotation of dimensions: from " + currentSliceDim + " to " + targetSliceDim);
        resliceCurrentImage(false);
      }
      if (targetSliceDim==2 && !sliceAxis_radio.getState("X")) sliceAxis_radio.activate("X");
      if (targetSliceDim==1 && !sliceAxis_radio.getState("Y")) sliceAxis_radio.activate("Y");
      if (targetSliceDim==0 && !sliceAxis_radio.getState("Z")) sliceAxis_radio.activate("Z");
      
      
      // now adjust slice selector
      
      if (currentSliceAxis != targetSliceDim){
        currentSliceEachAxis[currentSliceAxis] = currentSlice;
        int sliceCount = imData.currentStack().im.length;
        currentSliceSlider.setRange(0, sliceCount-1);
        currentSlice = currentSliceEachAxis[targetSliceDim];
        currentSliceSlider.setValue(currentSlice+0.1);
        currentSliceAxis = targetSliceDim;
      }
    }
    

    background( 0 );
    scale(-drawScalingFactor,drawScalingFactor,drawScalingFactor);
    // drawAxes(300);
    PVector offSet = new PVector(0, 0, 0);
    int priorTimes = 0;
    int postTimes = 0;
    //boolean tracksInClassColours = false;
    if (multiTimes) {
      // offSet = new PVector(50, 0, 120);
      offSet = new PVector(dataset.positionOffSetForMultiTimesteps[0], dataset.positionOffSetForMultiTimesteps[1], dataset.positionOffSetForMultiTimesteps[2]);
      priorTimes=timeRangeRadius;
      postTimes=timeRangeRadius;
      //tracksInClassColours=true;
    }


    for (int tOff = -1*priorTimes; tOff <= postTimes; tOff++) {
      int tsIndex = currentImageNum + tOff;
      if (tsIndex>=0 && tsIndex<dataset.timeSteps.length) {
        drawImageData(dataset.imageDatasetsByTimeStep.get(dataset.timeSteps[tsIndex]), PVector.mult(offSet, tOff));
      }
    }

    // this is for showing track trajectories only, all other object data display is within drawImageData
    if (showObjects) {
      if (objectTypesDisplayed.getState("Track") && dataset.tracksByClass() != null) {
        for (int classNum : dataset.objectClasses) {
          boolean showSelectTrack = filterObjects.getState("Selected") && filterObjectsByClass.getState("Selected-" + classNum);
          if (!classesDisplayedObject.getState("c" + classNum)) {
            continue;
          }
          if (!objectsByClasses.getState("Track-" + classNum)) {
            continue;
          }
          HashMap<Integer, Track> tracks = dataset.tracksByClass().get(classNum);
          if (tracks==null) {
            continue;
          }
          for (Track tr : tracks.values()) {
            if (showSelectTrack && !trackInSelectionOrRelated(tr)) {
              continue;
            }
            // drawTrack(tr,timeSteps[currentImageNum]);
            drawTrack(tr, dataset.timeSteps[max(0, currentImageNum-priorTimes)], dataset.timeSteps[min(dataset.timeSteps.length-1, currentImageNum+postTimes)], dataset.timeSteps[currentImageNum], offSet);
          }
        }
      }
    }



    float incr = 0.05;
    float[] specialRotateAxis = {0, 0.05, -0.03};
    if (rotating[0]) {
      cam.rotateX(incr);
    }
    if (rotating[1]) {
      cam.rotateY(incr);
    }
    if (rotating[2]) {
      cam.rotateZ(incr);
    }
    if (rotatingSpecial || sequenceTimer>0) {
      cam.rotateX(specialRotateAxis[0]); 
      cam.rotateY(specialRotateAxis[1]); 
      cam.rotateZ(specialRotateAxis[2]);
    }
    if (recording || sequenceTimer>0) {
      // saveFrame("/home/james/movie_making/LLS_vis/frame_"+nf(frameNum, 6) + ".png");
      saveFrame("/data/james/image_data/LLS/movie_making/temp/frame_"+nf(frameNum, 6) + ".png");
      //saveScreen("/data/james/image_data/LLS/movie_making/temp/control_frame_"+nf(frameNum, 6) + ".png");
      saveGUIscreenshotAs.add("/data/james/image_data/LLS/movie_making/temp/control_frame_"+nf(frameNum, 6) + ".png");
      frameNum++;
    }
  }
  
  boolean trackInSelectionOrRelated(Track tr){
    boolean sel = selectedTracks.contains(tr.id);
    if (showChildTracks.getState() && tr.parentTrack != null && selectedTracks.contains(tr.parentTrack.id)){
        sel = true;
      }
      if (showParentTracks.getState() && tr.childTracks!=null){
        for (Track ch : tr.childTracks){
          if (selectedTracks.contains(ch.id)){
            sel = true;
          }
        }
      }
    return(sel);
  }

  void drawImageData(ImageData im, PVector posOffset) {
    if (showObjects) {
      noStroke();
      HashMap<Integer, HashMap<Integer, OBJECT>>  obByClass = im.objectsByClass();

      if (obByClass != null) {
        for (int classNum : dataset.objectClasses) {
          if (obByClass.containsKey(classNum)) {
            for (OBJECT ob : obByClass.get(classNum).values()) {
              drawObject(ob, posOffset);
            }
          }
        }
      }
    }
    if (showImage && im !=null) { 
      drawImageArray(im.currentStack(),  posOffset, true);
    }
  }
  
  void resliceCurrentImage(boolean posDirection){
      ImageData im = dataset.imageDatasetsByTimeStep.get(dataset.timeSteps[currentImageNum]);
      if (im==null) return;
      im.currentStack().changeAxis(posDirection);
      im.currentStack().alphaMask();
  }
  


  void keyPressed() {

    // println(key + " " + keyCode);
    if (key == ' ') {
      println();
      println("Camera position " + cam.getPosition()[0] +", " + cam.getPosition()[1] +", " + cam.getPosition()[2]);
      println("Camera looking at " + cam.getLookAt()[0] +", " + cam.getLookAt()[1] +", " + cam.getLookAt()[2] + " from distance " + cam.getDistance(), " rotations " +  cam.getRotations()[0] +", " + cam.getRotations()[1] +", " + cam.getRotations()[2]);
      //println("  Frame rate: " + String.format("%.2f", runCtrl.frame_rate_achieved)  + " (previous: " + String.format("%.2f", runCtrl.frame_rate_achieved_previous) + "; target: " + runCtrl.targetFrameRate + ")");
    } 
    if (key == 'l'){
      println("reset camera");
      cam.lookAt(-513.88635, 706.9211, 679.7949,1384.6190622537536); //-426.4305, 554.72253, 472.69815, 1259.6013188844017
      cam.setRotations(2.4166856, 0.06674353, -0.59454507); // 3.0559223, 0.22465342, -1.4829687
    }
    if (key == 'p') {
      int cci = currentClassifiedImage == null ? 0 : (int) round(currentClassifiedImage.getValue());
      String filename = "ss_"+ dataset.timeSteps[currentImageNum] + "_" + cci + "_" + timeStepCounter;
      //String pth = ss_dataPath + "/" + filename + ".png";
      String pth = sketchPath() + "/data/screenshots/" + filename + ".png";
      
      saveFrame(pth);
      println("Saved screen view as " +  pth);
      // runCtrl.shotsTakenThisTimeStep += 1;
    }
    // print screen crashes if you switch between image types (eg original and seg) and don't do anything else (have to use mouse maybe?)
    if (key == 'P') {
      recording = !recording;
    }
    if (key == 'X') {
      rotating[0] = !rotating[0];
    }
    if (key == 'Y') {
      rotating[1] = !rotating[1];
    }
    if (key == 'Z') {
      rotating[2] = !rotating[2];
    }
    if (key == 'R') {
      rotatingSpecial = !rotatingSpecial;
    }

    if (key == 'T') {
      sequenceTimer = sequenceTimerInit;
    }


    // controls for image selection

    if (key == '.') {
      if (currentImageNumSlider!=null) {
        currentImageNumSlider.setValue((currentImageNum+1)%dataset.imageDatasetsByTimeStep.size() +0.01);
        println("Showing image " + currentImageNum);
      }
    }
    if (key == ',') {
      if (currentImageNumSlider!=null) {
        currentImageNum--;
        if (currentImageNum < 0) {
          currentImageNum = dataset.imageDatasetsByTimeStep.size()-1;
        }
        currentImageNumSlider.setValue(currentImageNum+0.01);
        println("Showing image " + currentImageNum);
      }
    }

    // controls for what types of things are shown
    if (key == 'x') {
      toggleSwitch("showImage");
    }
    if (key == 'z') {
      toggleSwitch("showObjects");
    }

    if (key == 's') {
      int m = (int) imageDisplayMode.getValue() + 1;
      if (m>=imageDisplayMode.getItems().size()){
        m = 0;
      }
      imageDisplayMode.activate(m);
      println("Image display mode " + imageDisplayMode.getValue());
    }
    if (key == 'a') {
      int m = (int) imageDisplayMode.getValue() - 1;
      if (m<0){
        m = imageDisplayMode.getItems().size()-1;
      }
      imageDisplayMode.activate(m);
      println("Image display mode " + imageDisplayMode.getValue());
    }
    
    // TODO: redo key bindings, objectTypesDisplayed and maybe everything else

    if (key == '`') {
      filterObjects.toggle("Size");
    }
    if (key == 'q') {
      objectTypesDisplayed.toggle(0); // "Mesh"
    }
    if (key == 'w') {
      objectTypesDisplayed.toggle(1);
    }
    if (key == 'e') {
      objectTypesDisplayed.toggle(2);
    }
    if (key == 'r') {
      objectTypesDisplayed.toggle(3);
    }
    if (key == 't') {
      objectTypesDisplayed.toggle(4);
    }
    if (key == 'y') {
      int numberObSets = dataset.objectAndTrackNames.size();
      if (numberObSets>0) {
        int newVal = (int) (currentObjectSet.getValue() +1)% numberObSets;
        currentObjectSet.activate(newVal);
      }
    }
    if (key == 'c') {
      showNodeContactMetrics = !showNodeContactMetrics;
      println("showNodeContactMetrics: "+showNodeContactMetrics);
    }



    // controls for what part of image shown
    if (key == 'f') {
      if (subsetSlices.getState("Show slice")) {
        subsetSlices.deactivate("Show slice");
      } else {
        subsetSlices.activate("Show slice");
      }
    }
    if (key == 'h') {
      if (subsetSlices.getState("Show below")) {
        subsetSlices.deactivate("Show below");
      } else {
        subsetSlices.activate("Show below");
      }
    }
    if (key == 'g') {
      if (subsetSlices.getState("Show above")) {
        subsetSlices.deactivate("Show above");
      } else {
        subsetSlices.activate("Show above");
      }
    }


    if (key == '\\') {
      // redo alpha mask on current stack
      dataset.imageDatasetsByTimeStep.get(dataset.timeSteps[currentImageNum]).currentStack().alphaMask();
    }
    if (key == '/') {
      resliceCurrentImage(true);
    }
    if (key == ';') {
      if (resliceMode_radio.getState("Auto")) {
        resliceMode_radio.deactivate("Auto");
      } else {
        resliceMode_radio.activate("Auto");
      }
    }
    


    // select classified image to show
    //for (int i=0; i< imageData().imgClNames.length; i++) {
    //  if (str(key).equals(str(i+1))) {
    //    currentClassifiedImage = i;
    //    println("Showing classified image " + (currentClassifiedImage+1) + ": " + imageData().imgClNames[currentClassifiedImage]);
    //  }
    //}
    if (key == CODED) {
      if (keyCode == LEFT || keyCode == RIGHT) {
        int cci = (int) currentClassifiedImage.getValue();
        if (keyCode == LEFT) {
          cci -= 1;
          if (cci < 0) {
            cci = dataset.segmentationNames.size()-1;
          }
        } else {
          cci = (cci+1) % dataset.segmentationNames.size(); // imageData().imgClNames.length;
        }

        currentClassifiedImage.activate(cci);
        println("Displaying segmentation "+dataset.segmentationNames.get(cci));
      }

      if (keyCode == UP) {
        //println("\nCurrent slice number: " + (currentSlice));
        int slices = dataset.sliceCount;
        if (slices>0) {
          currentSlice = (currentSlice+(shiftIsPressed ? 10 : 1)) % slices;
          currentSliceSlider.setValue(currentSlice+0.1); // to avoid weird floating point error and truncation issue
          println("Current slice number: " + (currentSlice));
        }
      }
      if (keyCode == DOWN) {
        //println("\nCurrent slice number: " + (currentSlice));
        int slices = dataset.sliceCount;
        if (slices>0) {
          currentSlice-=(shiftIsPressed ? 10 : 1);   
          if (currentSlice<0) {
            currentSlice = slices-1;
          }
          currentSliceSlider.setValue(currentSlice+0.1);
          println("Current slice number: " + (currentSlice));
        }
      }
    }
    if (keyCode == SHIFT) {
      shiftIsPressed = true;
    }
  }
  void keyReleased() {
    if (key==CODED) {
      if (keyCode == SHIFT) { 
        shiftIsPressed = false;
      }
    }
  }


  void drawObject(OBJECT o, PVector posOffset) {  
    if (!o.isVisible()) {
      return;
    }
    boolean showSelectTrack = filterObjects.getState("Selected") && filterObjectsByClass.getState("Selected-" + o.classNum);

    if (showSelectTrack){
      if (o.trackNode == null || !trackInSelectionOrRelated(o.trackNode.track)){return;}
    }
    //if (showSelectTrack && (o.trackNode == null || !selectedTracks.contains(o.trackNode.track.id))) {
    // if (showSelectTrack && (o.trackNode == null || !(selectedTracks.contains(o.trackNode.track.id) || (showChildren && o.trackNode.track.parentTrack != null && selectedTracks.contains(o.trackNode.track.parentTrack.id) )  ))) {return;}
    noStroke();
    boolean showTracks = objectTypesDisplayed.getState("Track") && objectsByClasses.getState("Track-" + o.classNum);
    int colourScheme = (int) objectColourScheme.getValue();
    int col =0;
    if (colourScheme>0) {
      int id = colourScheme==1 || o.trackNode == null ? o.id : (colourScheme==2 || o.trackNode.track == null ? o.trackNode.id : o.trackNode.track.id );
      col = color(17*id % 256, 57*id % 256, 113*id % 256);
    }

    if (objectTypesDisplayed.getState("Centre") && objectsByClasses.getState("Centre-" + o.classNum)) { 
      if (colourScheme==0) {
        //col=(showTracks && o.trackNode != null && o.trackNode.branchOrEnd && spec.classColoursHighlight != null) ? spec.classColoursHighlight.get(o.classNum) : spec.classColours.get(o.classNum);
        col = spec.classColours.get(o.classNum);
      }
      fill(col);
      pushMatrix();
      translate(o.centre.x + posOffset.x, o.centre.y + posOffset.y, o.centre.z + posOffset.z);
      //translate(ds.voxelDim[0] * centre.x, ds.voxelDim[1] * centre.y, ds.voxelDim[2] * centre.z);
      //println("object centre " + (o.centre.x + posOffset.x) +", "+ (o.centre.y + posOffset.y) +", "+ (o.centre.z + posOffset.z));

      sphere(  0.3 * pow(3* (float) o.volume/(4*PI), 1/3.0) );
      popMatrix();
    }
    boolean showId = objectTypesDisplayed.getState("Id") && objectsByClasses.getState("Id-" + o.classNum);
    boolean showTrackId = objectTypesDisplayed.getState("Track Id") && objectsByClasses.getState("Track Id-" + o.classNum) && o.trackNode != null;
    if (showId || showTrackId) { 
      if (colourScheme==0) {
        col=spec.classColours.get(o.classNum);
      }
      fill(col);
      pushMatrix();
      translate(0 + posOffset.x, 0 + posOffset.y, o.centre.z + posOffset.z);
      //translate(ds.voxelDim[0] * centre.x, ds.voxelDim[1] * centre.y, ds.voxelDim[2] * centre.z);
      String label = (showId ? o.id : "") + (showId && showTrackId ? " / " : "") + (showTrackId ? o.trackNode.track.id : "");
      text(label, o.centre.x, o.centre.y); 
      popMatrix();
    }
    if (objectTypesDisplayed.getState("Touching") && objectsByClasses.getState("Touching-" + o.classNum) && o.adjacencies != null) {
      beginShape( LINES );
      stroke(255);
      for (OBJECT ob : o.adjacencies.keySet()) {
        if (ob.id>o.id) continue;
        if (!ob.isVisible()) continue;
        if (!objectsByClasses.getState("Touching-" + ob.classNum)) continue;
        if (filterObjects.getState("Size") && ob.volume < spec.objectThresholds.get(ob.classNum)) continue;
        float ad = sqrt(o.adjacencies.get(ob))/10.0;
        float maxWeight = 2;
        strokeWeight(maxWeight*ad/(maxWeight+ad));
        vertex(o.centre.x + posOffset.x, o.centre.y + posOffset.y, o.centre.z + posOffset.z);
        vertex(ob.centre.x + posOffset.x, ob.centre.y + posOffset.y, ob.centre.z + posOffset.z);

      }
      endShape();
      //strokeWeight(0.1);
    }
    if (o.skel != null && objectTypesDisplayed.getState("Skeleton") && objectsByClasses.getState("Skeleton-" + o.classNum) ) { //&& o.classNum==2
      if (colourScheme==0) {
        col=spec.classColours.get(o.classNum);
      }
      stroke(col);
      drawskeleton(o.skel, posOffset);
      // println("drawing skeleton");
    }
    if (objectTypesDisplayed.getState("Mesh") && objectsByClasses.getState("Mesh-" + o.classNum)) { // showMeshes
      if (o.objectMesh != null) {
        if (colourScheme==0) {
          // col=(showTracks && o.trackNode != null && o.trackNode.branchOrEnd && spec.meshColoursHighlight != null) ? spec.meshColoursHighlight.get(o.classNum) : spec.meshColours.get(o.classNum);
          col = spec.meshColours.get(o.classNum);
        }
        drawMesh(o.objectMesh, posOffset, col);
      }
    }
  }

  // draw tracks extending one timestep beyond indicated range in either direction, but without any additional info 
  void drawTrack(Track tr, int firstTimeStep, int lastTimeStep, int centreTimeStep, PVector posOffset) {
    
    for (int ts=firstTimeStep-1; ts<=lastTimeStep; ts++) {
      if ( (!tr.nodesByTime.containsKey(ts)) || tr.nodesByTime.get(ts) == null || tr.nodesByTime.get(ts).size()==0) {
        continue;
      }
      float xo = posOffset.x * (ts-centreTimeStep);
      float yo = posOffset.y * (ts-centreTimeStep);
      float zo = posOffset.z * (ts-centreTimeStep);
      for (TrackNode tn : tr.nodesByTime.get(ts)) {
        beginShape( LINES );  
        strokeWeight(2);
        stroke(spec.trackColours.get(tn.classNum));
        for (TrackNode tn2 : tn.succs) {
          vertex(tn.centre.x+xo, tn.centre.y+yo, tn.centre.z+zo);
          vertex(tn2.centre.x+xo+posOffset.x, tn2.centre.y+yo+posOffset.y, tn2.centre.z+zo+posOffset.z);
        }

        if (ts==firstTimeStep-1 || tn.objects == null || tn.objects.size()==0) {
          continue;
        }
        stroke(spec.classColours.get(tn.classNum));
        for (int ii=0; ii<tn.objects.size(); ii++) {
          for (int jj=0; jj<ii; jj++) {
            PVector p1 = tn.objects.get(ii).centre;
            PVector p2 = tn.objects.get(jj).centre;
            vertex(p1.x+xo, p1.y+yo, p1.z+zo); 
            vertex(p2.x+xo, p2.y+yo, p2.z+zo);
          }
        }
        endShape();
        // show node adjacency metrics
        if (showNodeContactMetrics){
          for (int i=0;i<tn.adjacent.size();i++){
            TrackNode tn2 = tn.adjacent.get(i);
            if (tn2.classNum!=tn.classNum){continue;}
            if (tn2.id<=tn.id){continue;}
            pushMatrix();
            translate((tn.centre.x+tn2.centre.x)/2 + xo, (tn.centre.y+tn2.centre.y)/2 + yo, (tn.centre.z+tn2.centre.z)/2 + zo);
            text(round(100*tn.adjacentNodeRelativeNodeDistance[i])+" / "+round(100*tn.adjacentNodeRelativeNodeContact[i]), 0.0, 0.0); 
            popMatrix();
          }
        }
      }
    }
    
  }

  void drawskeleton(Skeleton sk, PVector posOffset) {
    if (sk.table==null) {
      return;
    }
    for (int ii=0; ii<sk.table.getRowCount(); ii++) {
      TableRow r = sk.table.getRow(ii);
      //stroke(255);
      // stroke(255,10,10);
      line(r.getFloat("V1 x")+posOffset.x, r.getFloat("V1 y")+posOffset.y, r.getFloat("V1 z")+posOffset.z, 
        r.getFloat("V2 x")+posOffset.x, r.getFloat("V2 y")+posOffset.y, r.getFloat("V2 z")+posOffset.z);
      pushMatrix();
      translate(r.getFloat("V1 x")+posOffset.x, r.getFloat("V1 y")+posOffset.y, r.getFloat("V1 z")+posOffset.z);
      fill(200, 10, 200);
      sphere(1);
      popMatrix();
    }
  }

  void drawMesh(ObjectMesh m, PVector posOffset, color col) {
    // for (PVector[] f : m.triangles) {
    for (int f=0; f< m.triangles.length/3; f++) {
      beginShape(TRIANGLE);
      noStroke();
      // currentMesh.stroke(colour);
      // fill(colour);
      float sf = (3+m.normalDotLight[f])/4;
      fill(color(red(col)*sf, green(col)*sf, blue(col)*sf, alpha(col)));
      for (int v=0; v<3; v++) {
        int vPos = 3*m.triangles[3*f+v];
        vertex(m.vertices[vPos]+posOffset.x, m.vertices[vPos+1]+posOffset.y, m.vertices[vPos+2]+posOffset.z);
      }
      endShape();
      // outlines: 
      //int n = f.length;
      //for (int ii=0; ii<n; ii++){
      //  int jj = (ii+1) % n;
      //  line(f[ii].x,f[ii].y,f[ii].z,f[jj].x,f[jj].y,f[jj].z);
      //}
    }
  }

  void drawSlice(ImageStack imageArray, PVector posOffset, int z) {
    drawSlice(imageArray, posOffset, z, false);
  }
  void drawSlice(ImageStack imageArray, PVector posOffset, int z, boolean removeAlphaMask) {
    if (imageArray.im.length<=z || imageArray.im[z]==null) {
      return;
    }
    pushMatrix();

    if (imageArray.dimRotate==1) {
      float a = radians(270); 
      rotateX(a);
      rotateZ(a);
    }
    if (imageArray.dimRotate==2) {
      float a = radians(90); 
      rotateX(a);
      rotateY(a);
    }
    translate(posOffset.x, posOffset.y, posOffset.z + z*dataset.voxelDim[(2-imageArray.dimRotate)%3]);
    if (removeAlphaMask) {
      PImage im = imageArray.im[z].copy();
      im.filter(OPAQUE); 
      image(im, 0, 0, dataset.voxelDim[0] * im.width, dataset.voxelDim[1] * im.height);
    } else {
      image(imageArray.im[z], 0, 0, dataset.voxelDim[(3-imageArray.dimRotate)%3] * imageArray.im[z].width, dataset.voxelDim[(4-imageArray.dimRotate)%3] * imageArray.im[z].height);
    }
    popMatrix();
  }


  void drawImageArray(ImageStack imageArray, PVector posOffset) {
    drawImageArray(imageArray, posOffset, false);
  }

  void drawImageArray(ImageStack imageArray, PVector posOffset, boolean removeAlphaMaskForSingleSlice)
  {
    if (imageArray==null) return;
    if (subsetSlices.getState("Show slice")) {
      drawSlice(imageArray, posOffset, currentSlice, removeAlphaMaskForSingleSlice);
      return;
    }
    int camZ = ceil(cam.getPosition()[2]/(drawScalingFactor*dataset.voxelDim[2]));
    if (imageArray.dimRotate==1) {
      camZ = ceil(cam.getPosition()[1]/(drawScalingFactor*dataset.voxelDim[1]));
    }
    if (imageArray.dimRotate==2) {
      camZ = ceil(-cam.getPosition()[0]/(drawScalingFactor*dataset.voxelDim[0])); // since x axis flipped to get standard xyz orientation
    }
    int maxZ = imageArray.im.length-1;
    int minZ = 0;
    if (subsetSlices.getState("Show above")) {
      minZ = currentSlice;
    }
    if (subsetSlices.getState("Show below")) {
      maxZ = currentSlice;
    }
    noStroke();
    // println(minZ + " - " + maxZ);
    int z = maxZ;
    while (z>=max(camZ, minZ)) {
      if (!(z==currentSlice && currentSliceFlashing && sliceFlickerAlternator)) {
        drawSlice(imageArray, posOffset, z);
      }
      z--;
    }
    z = minZ;
    while (z<min(camZ, maxZ+1)) {
      if (!(z==currentSlice && currentSliceFlashing && sliceFlickerAlternator)) {
        drawSlice(imageArray, posOffset, z);
      }
      z++;
    }
  }

  void drawAxes(float len) {
    stroke(255, 10, 10);
    line(0, 0, 0, len, 0, 0);
    stroke(10, 255, 10);
    line(0, 0, 0, 0, len, 0);
    stroke(10, 10, 255);
    line(0, 0, 0, 0, 0, len);
  }
}
