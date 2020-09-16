
// simple display showing progress loading data, to be shown between specGui and gui
void progBar(String name, int count, int total, int x, int y, int barOffset, int barHeight, int barLength){
  fill(200);
  text(name + ": " + count + " / " + total + " loaded", x, y);
  int progPos = round(total>0 ? barLength * count / total : barLength); 
  rect(x,y+barOffset,progPos,barHeight);
  fill(50);
  rect(x+progPos,y+barOffset,barLength-progPos,barHeight);
}
void loadProgressDisplay(){
  background( 0 );
  textSize(18);
  int yPos = 100;
  int yIncrement = 100;
  int barOffset = 30;
  int barHeight = 15; 
  int barLength = 400;
  //int txt1 = color(160, 160, 160);
 // fill(txt1);
 if (spec.loadImageData){
  progBar("Original images",data_load_counts[0] , dataset.timeSteps.length , leftMargin, yPos, barOffset, barHeight, barLength);
  yPos += yIncrement;
  progBar("Segmented images",data_load_counts[1] , dataset.timeSteps.length , leftMargin, yPos, barOffset, barHeight, barLength);
  yPos += yIncrement;
  if (spec.loadProbMaps ){
    progBar("Probability maps",data_load_counts[2] , dataset.timeSteps.length , leftMargin, yPos, barOffset, barHeight, barLength);
    yPos += yIncrement;
  }
  if (spec.generateBlendedImages ){
    progBar("Blended images",data_load_counts[3] , dataset.timeSteps.length , leftMargin, yPos, barOffset, barHeight, barLength);
    yPos += yIncrement;
  }
 }
 if (spec.loadObjectData){
   progBar("Object data",data_load_counts[4] , dataset.timeSteps.length , leftMargin, yPos, barOffset, barHeight, barLength);
   yPos += yIncrement;
 }
 if (spec.loadTracks){
   progBar("Tracks",data_load_counts[5] , spec.segNames.size() * spec.objectAndTrackNames.size() , leftMargin, yPos, barOffset, barHeight, barLength);
 }
}

// GUI for selecting / editing spec


// ******************* GLOBAL STATE - STATEFULL GUI OBJECTS AND VARIABLES LINKED TO CONTROLS *******************************

Textfield pathAndName_textbox;
Textfield title_textbox;

Button loadImageData_button;
Button loadObjectData_button;
Button loadTracks_button;
Button generateBlendedImages_button;
Button loadProbMaps_button;
Textfield maxChannelPercentageThreshold_textbox;

FloatArrayControl logGammaRangeControl;

Textfield stackNameLookupFolder_textbox;
RadioButton stackNameLookupFolderOption; 

ScrollableList removeTimeStep;

RadioButton filenameStackNumberMethod_radio; 
Textfield startString_textbox;
Textfield endString_textbox;

ScrollableList removeSegmentation;
Textfield New_Segmentation_Folder;
Textfield New_Segmentation_Name;


ScrollableList removeObjectFolder;
Textfield New_Object_Folder;
Textfield New_Track_Filename;
Textfield New_Object_Name;

Textfield imageFolderSubfolder_textbox;
Textfield segsSubfolder_textbox;
Textfield probMapsSubfolder_textbox;

Textfield[][] scalingFactors = new Textfield[4][3];

FloatArrayControl positionOffSetForMultiTimestepsControl;

IntMapControl parentClassControl;
IntFloatMapControl objectThresholdsControl;
ColorControl objectColorsControl;
ColorControl meshColoursControl;
ColorControl trackColoursControl;
boolean rebuildGuiSpecControls = false;

// ************************************************** GUI LAYOUT PARAMETERS **************************************************************
// size( 400, 800)

int leftMargin = 20, horizontalRuleMargin=10, x_fileNameExtensions = 500, x_colors=300;
int y_loadSpec = 20, y_path = 75, y_toggles=125,  y_timeStep = 200, y_stackNameLookup = 280, y_segs = 350, y_objects = 440, y_relativePaths=550; // y_stackNameLookup = 220  y_timeStep = 305
int y_scaling = 650,y_colors = 670;

int removeTimeStep_itemHeight = 25, removeTimeStep_width = 200; // removeTimeStep_maxHeight=200, 

// int removeSegmentation_width=170, removeSegmentation_height=35;
int removeSegmentation_width=360, removeSegmentation_itemHeight=24, removeSegmentation_maxHeight=200;
int removeObjectFolder_width=360, removeObjectFolder_itemHeight=24, removeObjectFolder_maxHeight=200;
  
 
Textfield standard_textfield(String handlerMethodName,int x, int y, int w, int h, ControlFont cf){
    Textfield tf = cp5.addTextfield(handlerMethodName)
     .setPosition(x,y)
     .setSize(w,h)
     .setFont(cf)
     .setFocus(false)
     .setColor(color(255))
     .setColorActive(color(0))
     .setCaptionLabel("")
     .setAutoClear(false)
     ;
     return(tf);
  }
  
void specGui(boolean makeControls) {
  if (rebuildGuiSpecControls){
    makeControls=true;
    rebuildGuiSpecControls=false;
  }
  // println("Lauch spec GUI");
  
  int offColour = color(0, 45, 90); // default background
  int onColour = color(0, 170, 255);
  //int offColour = color(20, 20, 180);
  //int onColour = color(120, 120, 220);
  //int onColour_low = color(80, 80, 200);

  int txt1 = color(0, 102, 153);
  int txt2 = color(160, 160, 160);
  
  ControlFont cf0 = new ControlFont(createFont("Arial",10));
  ControlFont cf1 = new ControlFont(createFont("Arial",12));
  ControlFont cf2 = new ControlFont(createFont("Arial",14));
  ControlFont cf3 = new ControlFont(createFont("Arial",16));
  
  background( 0 );

  // ************************************************** CREATE GUI CONTROLS **************************************************************
  if (makeControls){
    Label.setUpperCaseDefault(false);
    if (cp5!=null){
      cp5.dispose();
    } 
    cp5 = new ControlP5(this);
    cp5.setFont(createFont("Arial",12));
  }
  
  // ********************************** load/save/launch **********************************
  
  if (makeControls){
  cp5.addButton("loadSpec")
     //.setValue(0)
     .setPosition(leftMargin,y_loadSpec)
     .setSize(200,30)
     .setLabel("Load data selection file")
     ;
  
  cp5.addButton("saveSpec")
     //.setValue(0)
     .setPosition(leftMargin+215,y_loadSpec)
     .setSize(200,30)
     .setLabel("Save data selection file")
     ;
  
  // offColour = color(0, 45, 90); // default background
  // onColour = color(0, 170, 255);
  cp5.addButton("launch")
     //.setValue(0)
     .setPosition(leftMargin+450,y_loadSpec-3)
     .setSize(280,36) 
     .setFont(cf3)
     .setLabel("Load data and launch visualiser")
     .setColorBackground(color(0,75,150))
     ;
     
  }
  
     
     
   // ********************************** dataset path and title **********************************
   
   textAlign(LEFT,TOP);

  fill(txt1);
  textSize(18);
  text("Dataset location:", leftMargin, y_path);
  //textSize(14);
  //fill(txt2);
  //textAlign(RIGHT,TOP);
  //text(spec.rootPath + spec.datasetFolder, 380, y_path+30);
  textAlign(LEFT,TOP);
  fill(txt1);
  textSize(18);
  text("Title:", leftMargin, y_path+48);
  
  if (makeControls){
    
    pathAndName_textbox = standard_textfield("set_pathAndName",200, y_path,500,30,cf2);
  
     cp5.addButton("lookupPath")
     //.setValue(0)
     .setPosition(720,y_path)
     .setSize(60,25)
     .setLabel("Select")
     ;
     
     title_textbox = standard_textfield("set_title",90, y_path+45,200,30,cf2);
  
  }
  if (!pathAndName_textbox.isFocus()){pathAndName_textbox.setText(spec.rootPath + spec.datasetFolder);}
  if (!title_textbox.isFocus()){title_textbox.setText(spec.datasetName == null ? "" : spec.datasetName);}
  
  // ********************************** toggles: loadImageData loadObjectData loadTracks and additional image data  **********************************
  fill(txt1);
  textSize(16);
  text("Data types: ", leftMargin+300, y_toggles);
  
  int x_tmp = leftMargin+400;
  if (makeControls){
    loadImageData_button = cp5.addButton("loadImageData_toggle")
    .setPosition(x_tmp, y_toggles)
    .setSize(116, 25)
    .setLabel("image data")
    .setFont(cf2)
    //.setColorForeground(offColour)
    //.setColorActive(onColour)
    // .setSwitch(true)
  ;
  loadObjectData_button = cp5.addButton("loadObjectData_toggle")
    .setPosition(x_tmp+122, y_toggles)
    .setSize(116, 25)
    .setLabel("object data")
    .setFont(cf2)
  ;
  loadTracks_button = cp5.addButton("loadTracks_toggle")
    .setPosition(x_tmp+244, y_toggles)
    .setSize(116, 25)
    .setLabel("track data")
    .setFont(cf2)
  ;
  
  
  }
    if (spec.loadImageData) loadImageData_button.setColorBackground(onColour); else loadImageData_button.setColorBackground(offColour);
    if (spec.loadObjectData) loadObjectData_button.setColorBackground(onColour); else loadObjectData_button.setColorBackground(offColour);
    if (spec.loadTracks) loadTracks_button.setColorBackground(onColour); else loadTracks_button.setColorBackground(offColour);
    
    
    
  // ********************************** additional image data options **********************************
  // to be shown only when spec.loadImageData==true
  
  if (makeControls){
    logGammaRangeControl = new FloatArrayControl(spec.logGammaRange, "logGammaRangeControl", 230,y_toggles+37,30,15,2,cf1);
    
    generateBlendedImages_button = cp5.addButton("generateBlendedImages_toggle")
      .setPosition(340, y_toggles+35)
      .setSize(80, 20)
      .setLabel("image+class")
      .setFont(cf1)
    ;

    loadProbMaps_button = cp5.addButton("loadProbMaps_toggle")
      .setPosition(425, y_toggles+35)
      .setSize(80, 20)
      .setLabel("prob maps")
      .setFont(cf1)
    ;
    maxChannelPercentageThreshold_textbox = standard_textfield("set_maxChannelPercentageThreshold",690, y_toggles+35,40,20,cf1);
  }
  if (spec.loadImageData){
    textSize(14);
    text("log gamma min/max/default: ", leftMargin, y_toggles+35);
    text("min % confidence shown: ", 510, y_toggles+35);
    
    logGammaRangeControl.show(true);
    generateBlendedImages_button.show();
    loadProbMaps_button.show();
    maxChannelPercentageThreshold_textbox.show();
    
    logGammaRangeControl.setText();
    generateBlendedImages_button.setColorBackground(spec.generateBlendedImages ? onColour : offColour);
    loadProbMaps_button.setColorBackground(spec.loadProbMaps ? onColour : offColour);
    if (!maxChannelPercentageThreshold_textbox.isFocus()){maxChannelPercentageThreshold_textbox.setText(Integer.toString(spec.maxChannelPercentageThreshold));}// == null ? "" : spec.datasetName);}
  } else {
    logGammaRangeControl.show(false);
    generateBlendedImages_button.hide();
    loadProbMaps_button.hide();
    maxChannelPercentageThreshold_textbox.hide();
  }
  

  // ********************************** timeStep selection **********************************
  
  stroke(150); line(horizontalRuleMargin, y_timeStep-15,800-horizontalRuleMargin, y_timeStep-15);
  textSize(18);
  text( (spec.timeSteps==null ? "?" : spec.timeSteps.length) + " time steps selected", leftMargin + 5, y_timeStep+5);
  int stNmCnt=0; 
  if (spec.stackNames!=null && spec.timeSteps!=null ) for (int i=0;i<spec.stackNames.size();i++) if (spec.stackNames.get(i)!=null) stNmCnt++;
  text( stNmCnt + " corresponding file names found", leftMargin + 5, y_timeStep+35);
  
  //text("Selected time steps: ", leftMargin, y_timeStep);
  
  // text("Number time steps: ", 600, y_timeStep);
  
  textSize(14);
  text("Add time(s): ", 570, y_timeStep);
  //text("Map filename to time: ", 360, y_timeStep);
  //text("stacks found: ", 400, y_timeStep+20);
  textSize(12);
  text("x-y for range", 570, y_timeStep+25);
  textSize(14);
  fill(txt2);

  
  
  if (makeControls){
    removeTimeStep = cp5.addScrollableList("RemoveTimeStep")
    .setPosition(leftMargin+330,y_timeStep+5)
    // .setSize(180,22)
    .setWidth(removeTimeStep_width)
    .setBackgroundColor(color(255))
    .setItemHeight(removeTimeStep_itemHeight)
    .setBarHeight(removeTimeStep_itemHeight)
    .setType(ControlP5.LIST) //default DROPDOWN I think - LIST keeps label in place
    .setOpen(false)
    ;
    removeTimeStep.setCaptionLabel(" List / Remove"); // Times
    removeTimeStep.getCaptionLabel().getStyle().marginTop = 3; //move down // marginLeft
    removeTimeStep.getCaptionLabel().getStyle().marginLeft = -2;
  
    //Textfield tf = 
    cp5.addTextfield("Add_TimeStep")
     .setPosition(670,y_timeStep+5)
     .setSize(40,25)
     .setFont(cf1)
     .setFocus(false)
     .setColor(color(255))
     .setColorActive(color(0))
     .setCaptionLabel("")
     ;

    cp5.addButton("clear_timeSteps")
       //.setValue(0)
       .setPosition(730,y_timeStep+5)
       .setSize(50,40)
       .setLabel("Reset")
       ;
 
  }
  
  ArrayList<String> theItems = new ArrayList<String>();
  for (int i=0; i<spec.timeSteps.length; i++){theItems.add(spec.timeSteps[i]+"   "+(spec.stackNames!=null && spec.stackNames.size()>i ? spec.stackNames.get(i) : "null"));}
  removeTimeStep.setItems(theItems);


     
     
   // ********************************** stack name lookup folder **********************************
     
     //stroke(150); line(horizontalRuleMargin, y_stackNameLookup-15,800-horizontalRuleMargin, y_stackNameLookup-15);
    //textSize(14);
    //fill(txt2);
    // if(spec.datasetName!=null) text(spec.datasetName, leftMargin+50, y_path+65);
  
     //textAlign(RIGHT,TOP);
   // if (spec.filenameLookupFolder!=null) text(spec.filenameLookupFolder, 700, y_stackNameLookup+22);
   // textAlign(LEFT,TOP);
  
    fill(txt1);
    textSize(14);
    text("Stack name lookup folder: ", leftMargin, y_stackNameLookup+3);
    text("Stack name to stack number mapping: ", leftMargin, y_stackNameLookup+36);
  
   if (makeControls){
     
     stackNameLookupFolder_textbox = standard_textfield("set_stackNameLookupFolder",215, y_stackNameLookup, 250,25,cf2);
     
     stackNameLookupFolderOption = cp5.addRadioButton("stackNameLookupFolderOption") // addRadioButton
    .setPosition(480, y_stackNameLookup+5)
    .setSize(90, 16) //20
    //.setColorForeground(offColour)
    //.setColorActive(onColour)
    .setColorLabel(color(255))
    .setItemsPerRow(3)
    .setSpacingColumn(10)
    .addItem("Image Folder", 0)
    .addItem("Object Folder", 1)
    .addItem("Select", 2)
    ;
    stackNameLookupFolderOption.getItem(0).getCaptionLabel().getStyle().marginLeft=2-90;
    stackNameLookupFolderOption.getItem(1).getCaptionLabel().getStyle().marginLeft=2-90;
    stackNameLookupFolderOption.getItem(2).getCaptionLabel().getStyle().marginLeft=2-70;
    

    
    filenameStackNumberMethod_radio = cp5.addRadioButton("filenameStackNumberMethod_radio") // addRadioButton
    .setPosition(300, y_stackNameLookup+40)
    .setSize(170, 16)
    .setColorLabel(color(255))
    .setItemsPerRow(2)
    .setSpacingColumn(10)
    .addItem("Alpha-numeric order", 0)
    .addItem("Parse between substrings", 1)
    ;
    filenameStackNumberMethod_radio.getItem(0).getCaptionLabel().getStyle().marginLeft=22-170;
    filenameStackNumberMethod_radio.getItem(1).getCaptionLabel().getStyle().marginLeft=2-170;
    set_stackNameLookupFolderOption_from_filenameLookupFolder();
    
    startString_textbox = standard_textfield("filename_parse_startString",690,y_stackNameLookup+40,40,16,cf1);
    endString_textbox = standard_textfield("filename_parse_endString",740,y_stackNameLookup+40,40,16,cf1);

   }
   
   
   
   if (spec.filenameStackNumberMethod.equals("alphanumeric") && !filenameStackNumberMethod_radio.getState(0)){
    filenameStackNumberMethod_radio.activate(0);
   } else if (spec.filenameStackNumberMethod.equals("between_substrings") && !filenameStackNumberMethod_radio.getState(1)){
    filenameStackNumberMethod_radio.activate(1);
   }
   
   
   
   if (!stackNameLookupFolder_textbox.isFocus()){stackNameLookupFolder_textbox.setText(spec.filenameLookupFolder == null ? "" : spec.filenameLookupFolder);}
   if (spec.filenameStackNumberStartStopSubstrings != null && spec.filenameStackNumberStartStopSubstrings.length == 2){
     if (!startString_textbox.isFocus()){startString_textbox.setText(spec.filenameStackNumberStartStopSubstrings[0] == null ? "" : spec.filenameStackNumberStartStopSubstrings[0]);}
     if (!endString_textbox.isFocus()){endString_textbox.setText(spec.filenameStackNumberStartStopSubstrings[1] == null ? "" : spec.filenameStackNumberStartStopSubstrings[1]);}
   }
     
  // ********************************** segmentations **********************************
  x_tmp=400+leftMargin;
  stroke(150); line(horizontalRuleMargin, y_segs-5,800-horizontalRuleMargin, y_segs-5);
  textSize(16);
  fill(txt1);
  text("Segmentations", leftMargin, y_segs);
  fill(txt2);
  if (spec.segFolders!=null) text("("+spec.segFolders.size()+")", leftMargin+120, y_segs);
  //text(Integer.toString(spec.segFolders.length), leftMargin+150, y_segs);
  if (makeControls){
    
    removeSegmentation = cp5.addScrollableList("RemoveSegmentation")
    .setPosition(leftMargin,y_segs+25)
    .setBackgroundColor(color(255))
    .setItemHeight(removeSegmentation_itemHeight)
    .setBarHeight(22)
    .setType(ControlP5.LIST) //default DROPDOWN I think - LIST keeps "Remove" label in place
    .setOpen(false)
    .setFont(cf2)
    ;
    //removeSegmentation.setCaptionLabel("Segmentation folder\n       [label]");
    removeSegmentation.setCaptionLabel("current segmentation folders   [label]");
    removeSegmentation.getCaptionLabel().getStyle().marginTop = 3; //move down // marginLeft
    New_Segmentation_Folder = cp5.addTextfield("New_Segmentation_Folder")
     .setPosition(x_tmp,y_segs+5)
     .setSize(170,20)
     .setFont(cf1)
     .setFocus(false)
     .setColor(color(255))
     .setColorCaptionLabel(txt1)
     .setColorActive(color(0))
     //.setLabel("Add Track")
     .setCaptionLabel("new segmentation folder")
     //.setCaptionLabel("")
     .setAutoClear(false)
     ;
    //tf.getCaptionLabel().getStyle().marginLeft=3;
    //tf.getCaptionLabel().getStyle().marginTop=-41;
    
    New_Segmentation_Name = cp5.addTextfield("New_Segmentation_Name")
     .setPosition(x_tmp+190,y_segs+5)
     .setSize(100,20)
     .setFont(cf1)
     .setFocus(false)
     .setColor(color(255))
     .setColorCaptionLabel(txt1)
     .setColorActive(color(0))
     //.setLabel("Add Track")
     .setCaptionLabel("optional label")
     //.setCaptionLabel("")
     .setAutoClear(false)
     ;
    
    cp5.addButton("Add_Segmentation_Folder")
       //.setValue(0)
       .setPosition(x_tmp+300,y_segs+5)
       .setSize(70,25)
       .setLabel("Add")
       ;
       cp5.addButton("Clear_Segmentation_Text")
       //.setValue(0)
       .setPosition(x_tmp+300,y_segs+35)
       .setSize(70,20)
       .setLabel("(clear text)")
       ;
  }
  if (spec.segFolders!=null){
    theItems = new ArrayList<String>();
    for (int i=0; i<spec.segFolders.size(); i++){
      theItems.add(spec.segFolders.get(i) + 
      (spec.segNames != null && spec.segNames.size()>i && spec.segNames.get(i) != null && !spec.segNames.get(i).equals("") ? "    ["+ spec.segNames.get(i) +"]" : ""));
    }
    removeSegmentation.setItems(theItems);
    removeSegmentation.setSize(removeSegmentation_width,min(removeSegmentation_maxHeight,removeSegmentation_itemHeight*(1+spec.segFolders.size())));
  }
  
   // ********************************** object data **********************************
   //fill(color(255));
   stroke(150); line(horizontalRuleMargin, y_objects-5,800-horizontalRuleMargin, y_objects-5);
  textSize(16);
  fill(txt1);
  text("Object Datasets", leftMargin, y_objects);
  fill(txt2);
  if (spec.objectfolders!=null) text("("+spec.objectfolders.size()+")", leftMargin+135, y_objects);
  //text(Integer.toString(spec.segFolders.length), leftMargin+150, y_segs);
  if (makeControls){
    removeObjectFolder = cp5.addScrollableList("RemoveObjectFolder")
    .setPosition(leftMargin,y_objects+25)
    .setBackgroundColor(color(255))
    .setItemHeight(removeObjectFolder_itemHeight)
    .setBarHeight(removeObjectFolder_itemHeight) // 35
    .setType(ControlP5.LIST)
    .setOpen(false)
    .setFont(cf2)
    ;
    removeObjectFolder.setCaptionLabel("current object data: folder / track file / label");
    removeObjectFolder.getCaptionLabel().getStyle().marginTop = 3; //move down // marginLeft
  
    //Textfield tf = 
    New_Object_Folder = cp5.addTextfield("New_Object_Folder")
     .setPosition(leftMargin+400,y_objects+5)
     .setSize(160,20)
     .setFont(cf1)
     .setFocus(false)
     .setColor(color(255))
     .setColorCaptionLabel(txt1)
     .setColorActive(color(0))
     //.setLabel("Add Track")
     .setCaptionLabel("new object folder")
     //.setCaptionLabel("")
     .setAutoClear(false)
     ;
      New_Track_Filename = cp5.addTextfield("New_Track_Filename")
     .setPosition(leftMargin+400,y_objects+55)
     .setSize(160,20)
     .setFont(cf1)
     .setFocus(false)
     .setColor(color(255))
     .setColorCaptionLabel(txt1)
     .setColorActive(color(0))
     //.setLabel("Add Track")
     .setCaptionLabel("track file (optional)")
     //.setCaptionLabel("")
     .setAutoClear(false)
     ;
     
    New_Object_Name = cp5.addTextfield("New_Object_Name")
     .setPosition(leftMargin+590,y_objects+5)
     .setSize(100,20)
     .setFont(cf1)
     .setFocus(false)
     .setColor(color(255))
     .setColorCaptionLabel(txt1)
     .setColorActive(color(0))
     //.setLabel("Add Track")
     .setCaptionLabel("optional label")
     //.setCaptionLabel("")
     .setAutoClear(false)
     ;
    
    cp5.addButton("Add_Object_Folder")
       //.setValue(0)
       .setPosition(400+320,y_objects)
       .setSize(70,25)
       .setLabel("Add")
       ;
       cp5.addButton("Clear_Object_Text")
       //.setValue(0)
       .setPosition(400+320,y_objects+35)
       .setSize(70,20)
       .setLabel("(clear text)")
       ;
  }
  if (spec.objectfolders!=null){
    theItems = new ArrayList<String>();
    for (int i=0; i<spec.objectfolders.size(); i++){
      theItems.add(spec.objectfolders.get(i) + " / " +
      (spec.trackNames != null && spec.trackNames.size()>i && spec.trackNames.get(i) != null && !spec.trackNames.get(i).equals("") ? spec.trackNames.get(i) : "(none)") + " / " +
      (spec.objectAndTrackNames != null && spec.objectAndTrackNames.size()>i && spec.objectAndTrackNames.get(i) != null && !spec.objectAndTrackNames.get(i).equals("") ? spec.objectAndTrackNames.get(i) : "(none)"));
    }
    removeObjectFolder.setItems(theItems);
    removeObjectFolder.setSize(removeObjectFolder_width,min(removeObjectFolder_maxHeight,removeObjectFolder_itemHeight*(1+spec.objectfolders.size())));
  }
     // ********************************** relative paths **********************************
   //fill(color(255));
   stroke(150); line(horizontalRuleMargin, y_relativePaths,800-horizontalRuleMargin, y_relativePaths);
  textSize(16);
  fill(txt1);
  text("Relative paths", leftMargin, y_relativePaths+10);
  textSize(14);
  fill(txt2);
  text("Original images: /" + spec.imageFolderSubfolder, leftMargin, y_relativePaths+30);
  text("Segmentations: /[segmentation name]/" + spec.segsSubfolder, leftMargin, y_relativePaths+45);
  text("Probability maps: /[segmentation name]/" + spec.probMapsSubfolder, leftMargin, y_relativePaths+60);
  text("Object representations: /[segmentation name]/[object folder]", leftMargin, y_relativePaths+75);
  fill(txt1);
  text("extension", x_fileNameExtensions, y_relativePaths+10);
  if (makeControls){
    imageFolderSubfolder_textbox = standard_textfield("imageFolderSubfolder_textchange",x_fileNameExtensions,y_relativePaths+35,120,13,cf1);
    segsSubfolder_textbox = standard_textfield("segsSubfolder_textchange",x_fileNameExtensions,y_relativePaths+50,120,13,cf1);
    probMapsSubfolder_textbox = standard_textfield("probMapsSubfolder_textchange",x_fileNameExtensions,y_relativePaths+65,120,13,cf1);
  }
  if (!imageFolderSubfolder_textbox.isFocus()){imageFolderSubfolder_textbox.setText(spec.imageFolderSubfolder);}
  if (!segsSubfolder_textbox.isFocus()){segsSubfolder_textbox.setText(spec.segsSubfolder);}
  if (!probMapsSubfolder_textbox.isFocus()){probMapsSubfolder_textbox.setText(spec.probMapsSubfolder);}
  
  // ********************************** scaling factors **********************************
  
  stroke(150); line(horizontalRuleMargin, y_scaling,800-horizontalRuleMargin, y_scaling);
  textSize(16);
  fill(txt1);
  text("Scaling factors", leftMargin, y_scaling+10);
  textSize(14);
  fill(txt2);
  text("Image", leftMargin, y_scaling+35);
  text("Object centre", leftMargin, y_scaling+50);
  text("Mesh", leftMargin, y_scaling+65);
  text("Skeleton", leftMargin, y_scaling+80);
  text("x", 130+20, y_scaling+20); text("y", 130+20+50, y_scaling+20); text("z", 130+20+100, y_scaling+20);
  
  if (makeControls){
    for (int i=0; i<4; i++){
      for (int j=0; j<3; j++){
        scalingFactors[i][j] = standard_textfield("scalingFactorInput_"+i+"_"+j,130+50*j,y_scaling+40+15*i,40,13,cf1); 
      }
    }
  }
  for (int i=0; i<4; i++){
   for (int j=0; j<3; j++){
     if (!scalingFactors[i][j].isFocus()){scalingFactors[i][j].setText(Float.toString(spec.scalingParams()[i][j]));}
   }
  }
  
  // ********************************** positionOffSetForMultiTimesteps **********************************
  fill(txt1);
  text("spatial offset for multiple times:", leftMargin, y_scaling+125);
  if (makeControls){
    positionOffSetForMultiTimestepsControl = new FloatArrayControl(spec.positionOffSetForMultiTimesteps, "positionOffSetForMultiTimestepsControl", 130,y_scaling+150,40,15,10,cf1);
  }
  positionOffSetForMultiTimestepsControl.setText();
  
  // ********************************** color controls **********************************
  int classBoxWidth=30, classBoxHeight=10, classBoxGap=10;
  textSize(16);
  fill(txt1);
  text("Object classes", x_colors, y_colors-10);
  textSize(14);
  //text("class", x_colors+120, y_colors+15);
  fill(txt2);
  text("add/remove:",x_colors+140, y_colors-10);
  text("Parent class", x_colors+10, y_colors+30);
  text("Voxel threshold", x_colors+5, y_colors+50);
  text("Object color", x_colors+20, y_colors+85);
  text("Mesh color", x_colors+20, y_colors+135);
  text("Track color", x_colors+20, y_colors+185);
  for (int clIndex=0;clIndex<spec.objectClasses.length;clIndex++){
    int cl = spec.objectClasses[clIndex];
    text(""+cl,x_colors+130+clIndex*(classBoxWidth+classBoxGap), y_colors+10);
  }
  if (makeControls){
    cp5.addTextfield("Add_Remove_Class")
     .setPosition(x_colors+240, y_colors-10)
     .setSize(30,20)
     .setFont(cf1)
     .setFocus(false)
     //.setColor(color(255))
     //.setColorActive(color(0))
     .setCaptionLabel("")
     ;
  }
  if (makeControls){
    //if (parentClassControl!=null){parentClassControl.remove();}
    //if (objectThresholdsControl!=null){objectThresholdsControl.remove();}
    //if (objectColorsControl!=null){objectColorsControl.remove();}
    //if (meshColoursControl!=null){meshColoursControl.remove();}
    //if (trackColoursControl!=null){trackColoursControl.remove();}
    parentClassControl = new IntMapControl(spec.parentClasses,spec.objectClasses, "parentClassControl", x_colors+120, y_colors+35, classBoxWidth,15,classBoxGap,cf1);
    objectThresholdsControl = new IntFloatMapControl(spec.objectThresholds,spec.objectClasses, "objectThresholdsControl", x_colors+120, y_colors+55, classBoxWidth,15,classBoxGap,cf0);
    objectColorsControl = new ColorControl(spec.classColours,spec.objectClasses, "objectColorsControl", x_colors+120, y_colors+75, classBoxWidth,classBoxHeight,classBoxGap,cf0);
    meshColoursControl = new ColorControl(spec.meshColours,spec.objectClasses, "meshColoursControl", x_colors+120, y_colors+125, classBoxWidth,classBoxHeight,classBoxGap,cf0);
    trackColoursControl = new ColorControl(spec.trackColours,spec.objectClasses, "trackColoursControl", x_colors+120, y_colors+175, classBoxWidth,classBoxHeight,classBoxGap,cf0);
    // resetObjectClassControls=false;
  }
  parentClassControl.setText();
  objectThresholdsControl.setText();
  objectColorsControl.setTextAndColor();
  meshColoursControl.setTextAndColor();
  trackColoursControl.setTextAndColor();
  
  

  // ********************************** finalise **********************************
  if (makeControls){
  // move any drop down lists to front in required order for visibility
     removeObjectFolder.bringToFront();
     removeSegmentation.bringToFront();
     removeTimeStep.bringToFront();
     spec.init(); // not sure if needed
  } 
}
