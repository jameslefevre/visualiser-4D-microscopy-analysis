// After the data selection and loading step, the gui defined here runs on the main window. It is in charge of (most) global state (what to show and how). 
// The visualiser window is in a subprocess, an inner class also inheriting from PApplet)
// State may also changed via keyboard input (see Visualiser.keyPressed()); mostly this acts via the GUI controls, but there are also "hidden" features (minor / experimental) which work via variables in Visualiser class.

// GUI implemented with ControlP5 library:
// http://www.sojamo.de/libraries/controlP5/reference/index.html
// http://www.sojamo.de/libraries/controlP5/examples/extra/ControlP5withPeasyCam/ControlP5withPeasyCam.pde


// ******************* GLOBAL STATE - STATEFUL GUI OBJECTS AND VARIABLES LINKED TO CONTROLS *******************************

int currentImageNum = 0;
Slider currentImageNumSlider;

RadioButton currentClassifiedImage;

RadioButton currentObjectSet; // holds value

// display variables
boolean showImage = true; // linked to button
boolean showObjects = false; // linked to button


boolean showGammaTransform = false; // linked to button
float logGamma;
Slider gammaSlider;



// image display
RadioButton imageDisplayMode; 
CheckBox classesDisplayedCI;
HashMap<Integer,Boolean> colClassesCIvisible = new HashMap<Integer,Boolean>();
int[] currentSliceEachAxis = new int[3];
int currentSliceAxis=0;
int currentSlice = 0;
Slider currentSliceSlider;
RadioButton subsetSlices;
boolean currentSliceFlashing = false; // linked to button

RadioButton resliceMode_radio;
RadioButton sliceAxis_radio;


// object display
CheckBox classesDisplayedObject;
String[] objectTypes = {"Mesh", "Centre", "Skeleton", "Touching", "Track", "Id", "Track Id"};
CheckBox objectTypesDisplayed, objectsByClasses;

String[] objectFilterTypes = {"Size", "Tracked", "Selected"};
CheckBox filterObjects, filterObjectsByClass;

ArrayList<Integer> selectedTracks = new ArrayList<Integer>(); // linked to addTextfield("trackSelection")
//DropdownList 
ScrollableList removeTrackSelection;
Toggle showParentTracks;
Toggle showChildTracks;

RadioButton objectColourScheme; // holds value
boolean multiTimes = false; // linked to button
int timeRangeRadius = 1; // linked to addTextfield("timeRange")
Textfield timeRange;
Textfield[] timeStepPositionOffsets = new Textfield[3];

Textfield[] cameraPosition = new Textfield[3];
Textfield[] cameraTarget = new Textfield[3];

// run first time with makeControls==true
// existing controls are drawn automatically,
// so on subsequent iterations run with makeControls==false,
void gui(boolean makeControls) {
   
  // ************************************************** GUI LAYOUT PARAMETERS **************************************************************
  int x0=20, x1=220, x_subsetSlices = 70, x_reslice = 70;
  int y_imageSelect = 30, y_showImages=200, y_imageDisplayMode=260,  y_classesDisplayedCI=360,  y_objectTypesDisplayed = 285,
  y_filter = 470, y_trackSelection = 545,  y_objectColourScheme = 630, y_currentSlice = 390, y_multiTimes = 720;
  // y_filter = 470, y_trackSelection = 545,  y_objectColourScheme = 630, y_currentSlice = 390, y_multiTimes = 680, y_camera = 750; // , y_classes = 400 // for start of camera position stuff
  
  
  int x_showGammaTransform=x_subsetSlices;
  int y_showGammaTransform= y_currentSlice+5;
  
  int height_currentSlice = 360;
  int y_subsetSlices = y_currentSlice + 110;
  int y_currentSliceFlashing = y_currentSlice + 180;
  int y_reslice = y_currentSliceFlashing + 120;
  int offColour = color(20, 20, 180);
  int onColour = color(120, 120, 220);
  int onColour_low = color(80, 80, 200);
  //int offColour = color(220, 0, 220);
  //int onColour = color(222, 0, 0);
  //int onColour_low = color(0, 200, 0);
  
  int currentClassifiedImage_width = 120;
  int currentObjectSet_width = 80;
  int imageDisplayMode_width = 90;
  int classesDisplayedCI_totalWidth = 90;
  int classesDisplayedCI_maxWidth = 50;
  int classesDisplayedCI_gap = 3;
  int objectTypesDisplayed_width = 50;
  int classesDisplayedObject_totalWidth = 110;
  int classesDisplayedObject_maxWidth = 50;
  int objectColourScheme_width = 40;
  int classesDisplayedObject_gap = 3;
  
  int numClasses = dataset.objectClasses.length;
  int classes_width = min(classesDisplayedObject_totalWidth/numClasses-classesDisplayedObject_gap, classesDisplayedObject_maxWidth);
  // ************************************************** GUI DRAW **************************************************************
  
  //ControlFont cf1 = new ControlFont(createFont("Arial",12));
  //ControlFont cf2 = new ControlFont(createFont("Arial",14));
  //ControlFont cf3 = new ControlFont(createFont("Arial",16));
  
  background( 0 );
  textSize(12);
  fill(0, 102, 153);
  
  if (dataset.title !=null){
    textAlign(CENTER);textSize(18);
    text(dataset.title,200,20);
    textAlign(LEFT);textSize(12);
  }
  
  
  // ************************************************** CREATE GUI CONTROLS **************************************************************

  if (makeControls){cp5 = new ControlP5(this);}
  
  // ******************************* GUI CONTROLS - SELECT STACK NUMBER, CLASSIFIED IMAGE DATASET AND OBJECT DATASET  ****************************
  
  if (dataset.timeSteps != null){
    Integer ts = dataset.timeSteps[currentImageNum];
  text("Image "+ ts + ": " + dataset.stackNames.get(currentImageNum), x0, y_imageSelect+40); 
  }
  
  if (makeControls){

    int imNum = dataset.stackNames.size();
    println("Number of image datasets is " + imNum);
    if (imNum>1) {
      currentImageNumSlider = cp5.addSlider("currentImageNum")
        .setPosition(x0, y_imageSelect)
        .setSize(360, 15)
        //.setWidth(360)
        .setHandleSize(15)
        
        .setRange(0, imNum-1)
        
        .setSliderMode(Slider.FLEXIBLE)
        .setLabel("")
        ;
        if (imNum<11){
          currentImageNumSlider
          .snapToTickMarks(true)
          .setNumberOfTickMarks(imNum)
          ;
        }
    }
    
    currentClassifiedImage = cp5.addRadioButton("currentClassifiedImage") // addRadioButton
      .setPosition(x0, y_imageSelect + 50)
      .setSize(currentClassifiedImage_width, 16) //20
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingColumn(10)
      ;
      for (int ii =0; ii < dataset.segmentationNames.size(); ii++) {
      currentClassifiedImage.addItem(dataset.segmentationNames.get(ii), ii);
      Toggle it = currentClassifiedImage.getItem(ii);
      it.getCaptionLabel().getStyle().marginLeft=2-currentClassifiedImage_width;
    }
    currentClassifiedImage.activate(0);
  
    currentObjectSet = cp5.addRadioButton("currentObjectSet") // addRadioButton
      .setPosition(x1, y_imageSelect + 50)
      .setSize(currentObjectSet_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingColumn(10)
      ;
      for (int ii =0; ii < dataset.objectAndTrackNames.size(); ii++) {
      currentObjectSet.addItem(dataset.objectAndTrackNames.get(ii), ii);
      Toggle it = currentObjectSet.getItem(ii);
      it.getCaptionLabel().getStyle().marginLeft=2-currentObjectSet_width;
    
    }
    currentObjectSet.activate(0);
  }
  
  // ******************************* GUI CONTROLS - SHOW IMAGE OR OBJECT DATA OR BOTH ****************************

  if (makeControls){
    cp5.addButton("showImage") // addToggle
      .setSize(160, 40)
      .setPosition(x0, y_showImages)
      .setLabel("Show Images")
      .setSwitch(true)
      ;
    if (showImage) {
      toggleSwitch("showImage");
    }
  
    cp5.addButton("showObjects")
      .setSize(160, 40)
      .setPosition(x1, y_showImages)
      .setLabel("Show Objects")
      .setSwitch(true)
      ;
    if (showObjects) {
      toggleSwitch("showObjects");
    }
    
    cp5.addButton("toggleImageObjects")
      .setPosition(x0+165, y_showImages+5)
      .setSize(x1-x0-160-10, 30)
      .setLabel("")
    ;
  }
  
  
  // ******************************* GUI CONTROLS - IMAGE ALPHA AND GAMMA CONTROLS ****************************
  
  if (makeControls){
     cp5.addButton("showGammaTransform")
      .setSize(60, 20)
      .setPosition(x_showGammaTransform, y_showGammaTransform)
      .setLabel("Log Gamma")
      .setSwitch(true)
      ;
    if (showGammaTransform) {
      toggleSwitch("showGammaTransform");
    }
    
    gammaSlider = cp5.addSlider("logGamma")
        .setPosition(x_showGammaTransform,y_showGammaTransform+22)
        .setSize(60,10)
        //.setHandleSize(15)     
        .setRange(spec.logGammaRange[0], spec.logGammaRange[1])     
        .setSliderMode(Slider.FLEXIBLE)
        .setLabel("")
        .setValue(spec.logGammaRange[2])
        ;
       
    
  }

  
   // ******************************* GUI CONTROLS - SELECT WHICH IMAGE TYPE IS DISPLAYED, OPTION TO HIDE CHANNELS IN SEGMENTATION ****************************
   
  // textAlign(CENTER);textSize(18);
  text("Show channel",x0, y_classesDisplayedCI-5);
  
  if (makeControls){
    // http://www.sojamo.de/libraries/controlP5/reference/controlP5/RadioButton.html
    imageDisplayMode = cp5.addRadioButton("radioButton") // addRadioButton
      .setPosition(x0, y_imageDisplayMode)
      .setSize(imageDisplayMode_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingColumn(10)
      .addItem("Original", 0)
      .addItem("Segmentation", 1)
      ;
      if (dataset.hasProbMaps){
       imageDisplayMode.addItem("Probability map", 2);
      }
      if (dataset.hasBlendedImages){
        imageDisplayMode.addItem("Original with class", 3);
      }
    
   
  for (Toggle it : imageDisplayMode.getItems()) {
    it.getCaptionLabel().getStyle().marginLeft=2-imageDisplayMode_width;
  }
  imageDisplayMode.activate(0);
  
  int numSegColours = dataset.segmentationColours.size();
  if (numSegColours<1){numSegColours=1;}
  int classesCI_width = min(classesDisplayedCI_totalWidth/numSegColours-classesDisplayedCI_gap, classesDisplayedCI_maxWidth);
  classesDisplayedCI = cp5.addCheckBox("classesDisplayedCI")
    .setPosition(x0, y_classesDisplayedCI)
    .setSize(classesCI_width, 20)
    .setColorForeground(offColour)
    .setColorActive(onColour)
    .setColorLabel(color(255))
    .setItemsPerRow(numSegColours)
    .setSpacingColumn(classesDisplayedCI_gap)
    ;
    for (int ii=0; ii<numSegColours; ii++) {
      classesDisplayedCI.addItem("col" + (ii+1), 0).setCaptionLabel("col"+(ii+1));
      colClassesCIvisible.put(ii,true);
    }
    classesDisplayedCI.activateAll();
    for (Toggle it : classesDisplayedCI.getItems()) {
      it.getCaptionLabel().getStyle().marginLeft=-classesCI_width;
    }

  }
 // ******************************* GUI CONTROLS - SELECT WHICH OBJECTS AND ELEMENTS ARE DISPLAYED ****************************
 text("Classes:", x1, y_objectTypesDisplayed-13);
 text("Filters", x1, y_filter-13);
 
 if (makeControls){
   
   classesDisplayedObject = cp5.addCheckBox("classesDisplayedObject")
      .setPosition(x1+60, y_imageDisplayMode)
      .setSize(classes_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(numClasses)
      .setSpacingColumn(classesDisplayedObject_gap)
      ;
    for (int ii : dataset.objectClasses) {
      classesDisplayedObject.addItem("c" + ii, 0);
      //classesDisplayedObject.getItem("c" + ii).setLabel(""+ii);
    }
    classesDisplayedObject.activateAll();
    for (Toggle it : classesDisplayedObject.getItems()) {
      it.getCaptionLabel().getStyle().marginLeft=-4-classes_width/2;
    }
    // currentObjectSet.activate(currentObjectSetInitial);
   
    objectTypesDisplayed = cp5.addCheckBox("objectTypesDisplayed")
      .setPosition(x1, y_objectTypesDisplayed)
      .setSize(objectTypesDisplayed_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingColumn(10)
      ;
    for (int ii=0; ii< objectTypes.length; ii++) { 
      objectTypesDisplayed.addItem(objectTypes[ii], 0);
    }
    // http://www.sojamo.de/libraries/controlP5/examples/use/ControlP5controlFont/ControlP5controlFont.pde
    for (Toggle it : objectTypesDisplayed.getItems()) {
      it.getCaptionLabel().getStyle().marginLeft=2-objectTypesDisplayed_width;
    }
  
    objectsByClasses = cp5.addCheckBox("objectsByClasses")
      .setPosition(x1+60, y_objectTypesDisplayed)
      .setSize(classes_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour_low)
      .setColorLabel(color(255))
      .setItemsPerRow(numClasses)
      .setSpacingColumn(classesDisplayedObject_gap)
      ;
    for (int ii=0; ii< objectTypes.length; ii++) { 
      for (int jj : dataset.objectClasses) {
        objectsByClasses.addItem(objectTypes[ii] + "-" + jj, 0); // ii*10+jj
        objectsByClasses.activate(objectTypes[ii] + "-" + jj);
      }
    }
    objectsByClasses.activateAll();
    objectsByClasses.hideLabels();    
    
    filterObjects = cp5.addCheckBox("filterObjects")
      .setPosition(x1, y_filter)
      .setSize(objectTypesDisplayed_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingColumn(10)
      ;
    for (int ii=0; ii< objectFilterTypes.length; ii++) { 
      filterObjects.addItem(objectFilterTypes[ii], 0);
    }
    for (Toggle it : filterObjects.getItems()) {
      it.getCaptionLabel().getStyle().marginLeft=2-objectTypesDisplayed_width;
    }
  
    filterObjectsByClass = cp5.addCheckBox("filterObjectsByClass")
      .setPosition(x1+60, y_filter)
      .setSize(classes_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour_low)
      .setColorLabel(color(255))
      .setItemsPerRow(numClasses)
      .setSpacingColumn(classesDisplayedObject_gap)
      ;
    for (int ii=0; ii< objectFilterTypes.length; ii++) { 
      for (int jj : dataset.objectClasses) {
        filterObjectsByClass.addItem(objectFilterTypes[ii] + "-" + jj, 0); // ii*10+jj
        filterObjectsByClass.activate(objectFilterTypes[ii] + "-" + jj);
      }
    }
    filterObjectsByClass.activateAll();
    filterObjectsByClass.hideLabels();
    
    Textfield tf = cp5.addTextfield("Add_Track")
       .setPosition(x1,y_trackSelection+15)
       .setSize(50,20)
       //.setFont(font)
       .setFocus(false)
       .setColor(color(255))
       .setColorActive(color(0))
       //.setLabel("Add Track")
       .setCaptionLabel("Add Track")
       ;
    tf.getCaptionLabel().getStyle().marginLeft=3;
    tf.getCaptionLabel().getStyle().marginTop=-36;
    
       removeTrackSelection = cp5.addScrollableList("RemoveTrack")
      .setPosition(x1,y_trackSelection+40)
      .setSize(50,20)
      .setBackgroundColor(color(255))
      .setItemHeight(20)
      .setBarHeight(15)
      .setType(ControlP5.LIST) //default DROPDOWN I think - LIST keeps "Remove" label in place
      ;
      removeTrackSelection.setCaptionLabel("Remove");
      
      showParentTracks = cp5.addToggle("showParentTracks")
      .setPosition(x1+60, y_trackSelection+5)
      .setSize(50, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255)) 
      .setLabel("Parent")
      ;
    showParentTracks.getCaptionLabel().getStyle().marginTop=-15;
    showParentTracks.getCaptionLabel().getStyle().marginLeft=3;
    
    showChildTracks = cp5.addToggle("showChildTracks")
      .setPosition(x1+60, y_trackSelection+35)
      .setSize(50, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255)) 
      .setLabel("Children")
      ;
    showChildTracks.getCaptionLabel().getStyle().marginTop=-15;
    showChildTracks.getCaptionLabel().getStyle().marginLeft=3;
  
  }
  // ******************************* GUI CONTROLS - OBJECT COLOUR SCHEME ****************************

  text("Object Coloring", x1+30, y_objectColourScheme);
  if (makeControls){
  
    objectColourScheme = cp5.addRadioButton("objectColourScheme") // addRadioButton
      .setPosition(x1, y_objectColourScheme+10)
      .setSize(objectColourScheme_width, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(4)
      .setSpacingColumn(5)
      .addItem("Class", 0)
      .addItem("Object", 1)
      .addItem("Node", 2)
      .addItem("TrackId", 3)
      ;
    currentClassifiedImage.activate("Class");
    for (int ii =0; ii < 4; ii++) {
      Toggle it = objectColourScheme.getItem(ii);
      it.getCaptionLabel().getStyle().marginLeft=2-objectColourScheme_width;
    }
    objectColourScheme.getItem(3).setLabel("Track");
  }
// ******************************* GUI CONTROLS - SLICE SELECTION / HIGHLIGHT / SUBSET ****************************
  
  text("Slice display", x_subsetSlices-6, y_subsetSlices-35);
  text("and selection", x_subsetSlices-6, y_subsetSlices-20);
  text("Slice axis", x_reslice+3, y_reslice-13);
  
  if (makeControls){
    int sliceCount = dataset.sliceCount; 
    currentSliceSlider = cp5.addSlider("currentSlice")
      .setPosition(x0, y_currentSlice)
      // .setHeight(360)
      .setSize(15, height_currentSlice)
      //.setHandleSize(15)
      //.snapToTickMarks(true)
      .setRange(0, sliceCount-1)
      //.setNumberOfTickMarks(sliceCount)
      .setSliderMode(Slider.FLEXIBLE)
      ;
      
      
      subsetSlices = cp5.addRadioButton("subsetSlices") // addRadioButton
      .setPosition(x_subsetSlices, y_subsetSlices)
      .setSize(50, 20)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingColumn(10)
      .addItem("Show above", 0)
      .addItem("Show slice", 1)
      .addItem("Show below", 2)
      ;
      // subsetSlices.hideLabels();
    for (Toggle it : subsetSlices.getItems()) {
      it.getCaptionLabel().getStyle().marginLeft=2-50;
    }
    
    cp5.addButton("currentSliceFlashing")
      .setSize(50, 20)
      .setPosition(x_subsetSlices, y_currentSliceFlashing)
      .setLabel("Flicker")
      .setSwitch(true)
      ;
 
  sliceAxis_radio = cp5.addRadioButton("sliceAxis_radio")
      .setPosition(x_reslice, y_reslice)
      .setSize(20, 15)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(3)
      .setSpacingColumn(5)
      .addItem("X", 0)
      .addItem("Y", 0)
      .addItem("Z", 0)
      ;
      
      for (Toggle it : sliceAxis_radio.getItems()) { it.getCaptionLabel().getStyle().marginLeft=4-20; }
      sliceAxis_radio.activate(2);
      
   resliceMode_radio = cp5.addRadioButton("resliceMode_radio")
      .setPosition(x_reslice, y_reslice+20)
      .setSize(32, 15)
      .setColorForeground(offColour)
      .setColorActive(onColour)
      .setColorLabel(color(255))
      .setItemsPerRow(2)
      .setSpacingColumn(6)
      .addItem("Auto", 0)
      .addItem("Fixed", 0)
      ;
      
      for (Toggle it : resliceMode_radio.getItems()) { it.getCaptionLabel().getStyle().marginLeft=4-35; }
      

  }
   

// ******************************* GUI CONTROLS - DISPLAY MULTIPLE TIME POINTS ****************************
  
  text("Offset:", x1, y_multiTimes+45);
  
  if (makeControls){
    cp5.addButton("multiTimes") // addToggle
        .setSize(70, 20)
        .setPosition(x1, y_multiTimes)
        .setLabel("Multiple Times")
        .setSwitch(true)
        ;
    
     timeRange = cp5.addTextfield("change_timeRangeRadius")
         .setPosition(x1+145,y_multiTimes+2)
         .setSize(20,15)
         .setFocus(false)
         .setColor(color(255))
         .setCaptionLabel("Time steps +/-")
         .setAutoClear(false)
         ;
      timeRange.getCaptionLabel().getStyle().marginLeft=-60;
      timeRange.getCaptionLabel().getStyle().marginTop=-15;
      
      for (int j=0; j<3; j++){
        timeStepPositionOffsets[j] = standard_textfield("timeStepPositionOffsets_input_"+j,x1+50+40*j,y_multiTimes+30,35,15,new ControlFont(createFont("Arial",9))); 
      }
  }
  
  if (!timeRange.isFocus() && !timeRange.getText().equals(Integer.toString(timeRangeRadius))){timeRange.setText(Integer.toString(timeRangeRadius));}
  for (int j=0; j<3; j++){
     if (!timeStepPositionOffsets[j].isFocus() && !timeStepPositionOffsets[j].getText().equals(Float.toString(dataset.positionOffSetForMultiTimesteps[j]))){
       timeStepPositionOffsets[j].setText(Float.toString(dataset.positionOffSetForMultiTimesteps[j]));
     }
  }
  
// ******************************* GUI CONTROLS - CAMERA ****************************
  
  /*
  text("Camera:", x1-15, y_camera+15);
  text("LookAt:", x1-15, y_camera+35);
  
  
  if (makeControls){     
      for (int j=0; j<3; j++){
        cameraPosition[j] = standard_textfield("cameraPosition_input_"+j,x1+30+45*j,y_camera,42,12,new ControlFont(createFont("Arial",9))); 
        cameraTarget[j] = standard_textfield("cameraTarget_input_"+j,x1+30+45*j,y_camera+14,42,12,new ControlFont(createFont("Arial",9))); 
      }
  }
  if (visualiser!=null && visualiser.cam!=null){
    float[] camPos = visualiser.cam.getPosition();
    float[] camTar = visualiser.cam.getLookAt();
  
    for (int j=0; j<3; j++){
       if (!cameraPosition[j].isFocus()){
         cameraPosition[j].setText(Float.toString(camPos[j]));
       }
       if (!cameraTarget[j].isFocus()){
         cameraTarget[j].setText(Float.toString(camTar[j]));
       }
    }
  }
  */
  
// ******************************* FINALISE ****************************
  if (makeControls){
    // move any drop down lists to front in required order for visibility
    removeTrackSelection.bringToFront();
  }
}
   
