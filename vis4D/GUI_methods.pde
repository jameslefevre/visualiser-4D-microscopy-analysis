// methods that are triggered in GUI or GUIspec
// controlEvent is run automatically as part of the ControlP5 system, handling many events from the active ControlP5 instance
// other events (depending on the control and event type) are dispatched directly to handler methods without required code in controlEvent
// these other handler methods are given below

void controlEvent(ControlEvent theEvent) {
  
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    //println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
  } 
  else if (theEvent.isController()) {
    println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
    
    // ****** RemoveTrack control (GUI) ******
    if (theEvent.getController().toString().equals("RemoveTrack [ScrollableList]")){
      int removeItem = round(theEvent.getController().getValue());
      println("Removing selected track number " + removeItem);
      removeTrackSelection.removeItem(selectedTracks.get(removeItem).toString());
      selectedTracks.remove(removeItem);
      removeTrackSelection.setSize(50,min(200,20+20*selectedTracks.size()));
    }
  }
    
    // ************************************************** sliceAxis_radio control (GUIspec) **************************************************
    if(sliceAxis_radio != null && theEvent.isFrom(sliceAxis_radio) && visualiser != null) {
      println("Manual change in slice axis!");
      visualiser.manualResliceCurrentImage = true;
    }
    
    // ************************************************** timeStepPositionOffsets text fields (GUI) **************************************************
  
  if (theEvent.isController()){
    for (int j=0; j<3; j++){
      if (theEvent.getController().toString().equals("timeStepPositionOffsets_input_"+j+" [Textfield]")){
        float v = float(timeStepPositionOffsets[j].getText());
        if (Float.isNaN(v)){
          timeStepPositionOffsets[j].setText(Float.toString(dataset.positionOffSetForMultiTimesteps[j]));
        } else {
          dataset.positionOffSetForMultiTimesteps[j] = v;
        }
      }
    }
  }
  
  
    
    
  // ****** RemoveTimeStep control (GUIspec) ******
  if (theEvent.isController()){
    if (theEvent.getController().toString().equals("RemoveTimeStep [ScrollableList]") && spec.timeSteps != null && spec.timeSteps.length>0 ){
      // remove selected time step from spec.timeSteps (painfully, because it is int[]), then reset removeTimeStep 
      int removeItem = round(theEvent.getController().getValue()); // index of selected item (to be removed)
      println("Removing selected time step " + removeItem);
      int[] ts = new int[spec.timeSteps.length-1];
      for (int i=0;i<removeItem;i++) ts[i]=spec.timeSteps[i];
      for (int i=removeItem+1;i<spec.timeSteps.length;i++) ts[i-1]=spec.timeSteps[i];
      spec.timeSteps = ts;
      spec.init();
    }
  }
  // ****** RemoveSegmentation control (GUIspec) ******
  if (theEvent.isController()){
    if (theEvent.getController().toString().equals("RemoveSegmentation [ScrollableList]") && spec.segFolders != null && spec.segFolders.size()>0 ){
      int removeItem = round(theEvent.getController().getValue()); // index of selected item (to be removed)
      println("Removing selected segmentation " + removeItem);
      spec.segFolders.remove(removeItem);
      if (spec.segNames != null && spec.segNames.size()>removeItem){
        spec.segNames.remove(removeItem);// = tmp;
      }
      spec.init();
    }
  }
  
  // ****** RemoveObjectFolder control (GUIspec) ******
  if (theEvent.isController()){
    if (theEvent.getController().toString().equals("RemoveObjectFolder [ScrollableList]") && spec.objectfolders != null && spec.objectfolders.size()>0 ){
      int removeItem = round(theEvent.getController().getValue()); // index of selected item (to be removed)
      println("Removing selected object dataset " + removeItem);
      spec.objectfolders.remove(removeItem);
      if (spec.trackNames != null && spec.trackNames.size()>removeItem){
        spec.trackNames.remove(removeItem);
      }
      if (spec.objectAndTrackNames != null && spec.objectAndTrackNames.size()>removeItem){
        spec.objectAndTrackNames.remove(removeItem);
      }
      spec.init();
    }
  }
  
  //if (theEvent.isController()){
  if (parentClassControl != null) parentClassControl.eventHandler(theEvent);
  if (objectThresholdsControl != null) objectThresholdsControl.eventHandler(theEvent);
  if (objectColorsControl != null) objectColorsControl.eventHandler(theEvent);
  if (meshColoursControl != null) meshColoursControl.eventHandler(theEvent);
  if (trackColoursControl != null) trackColoursControl.eventHandler(theEvent);
  
  if (logGammaRangeControl != null) logGammaRangeControl.eventHandler(theEvent);
  
  if (positionOffSetForMultiTimestepsControl != null) positionOffSetForMultiTimestepsControl.eventHandler(theEvent);
  
  // ************************************************** stackNameLookupFolderOption control (GUIspec) **************************************************
  if(stackNameLookupFolderOption != null && theEvent.isFrom(stackNameLookupFolderOption)) {
    if (stackNameLookupFolderOption.getState(0)){
    spec.filenameLookupFolder = spec.imageFolderPath();
    } else
    if (stackNameLookupFolderOption.getState(1)){
      spec.filenameLookupFolder = spec.objectFolderPath(0,0);
    } else 
    if (stackNameLookupFolderOption.getState(2)) {
      File dir  = new File(spec.rootPath+spec.datasetFolder); 
      selectFolder("Select a folder for looking up stack names:", "selectLookupFolder",dir);
    }
    spec.init();
  }
  
  // ************************************************** filenameStackNumberMethod_radio control (GUIspec) **************************************************
  if(filenameStackNumberMethod_radio != null && theEvent.isFrom(filenameStackNumberMethod_radio)) {
    set_filenameStackNumberMethod_from_radiobutton();   
    spec.init();
  }
  
  // ************************************************** scalingFactors text fields (GUIspec) **************************************************
  
  if (theEvent.isController()){
    for (int i=0; i<4; i++){
      for (int j=0; j<3; j++){
        if (theEvent.getController().toString().equals("scalingFactorInput_"+i+"_"+j+" [Textfield]")){
          float v = float(scalingFactors[i][j].getText());
          if (Float.isNaN(v)){
            scalingFactors[i][j].setText(Float.toString(spec.scalingParams()[i][j]));
          } else {
            spec.scalingParams()[i][j] = v;
          }
        }
      }
    }
  }
}

// *********************************************************************** GUI CONTROL HANLDER METHODS ************************************************************************

void toggleImageObjects() {
  toggleSwitch("showObjects");
  toggleSwitch("showImage");
}

void toggleSwitch(String name) {
  Button b = (Button) cp5.get(name);
  if (b.isOn()) {
    b.setOff();
  } else {
    b.setOn();
  }
}


void showGammaTransform(boolean val){
  println(val);
  showGammaTransform = val;
  if (!val){return;}
  boolean recalc = false;
  if (spec.logGammaRange[2] != logGamma){
    spec.logGammaRange[2] = logGamma;
    recalc = true;
  }
  for (int imageNumber : dataset.timeSteps){
    ImageData id = dataset.imageDatasetsByTimeStep.get(imageNumber); 
    if (id==null){continue;}
    if (recalc || id.imgAdjusted == null){
      id.calculateGammaAdjustedImage(exp(logGamma));
    }
  } 
}

void Add_Track(String input){
  println("Adding track selection "+input);
  //int val = Integer.valueOf(input);
  Integer val = int(input);
  println(input+" "+val);
  if (!input.equals(val.toString())){
    return;
  }
  println("Adding track id " + val);
    selectedTracks.add(val);
    removeTrackSelection.addItem(input,true);
    removeTrackSelection.setSize(50,min(200,20+20*selectedTracks.size()));
  }

void change_timeRangeRadius(String input){
  int v = int(input);
  if (input.equals(Integer.toString(v))){
    timeRangeRadius = v;   
  }
  }  

// see 2nd example, http://www.sojamo.de/libraries/controlP5/reference/index.html
// for objectTypesDisplayed


// *********************************************************************** GUIspec CONTROL HANLDER METHODS ************************************************************************

void selectLookupFolder(File fileSelection){
  if (fileSelection != null){spec.filenameLookupFolder  = fileSelection.getAbsolutePath();}
  spec.init();
}


  // ********************************** load/save/launch (GUIspec) **********************************


void loadSpec(){
  // note that loadSelectedSpec is called async, so code that assumes new spec has been loaded must be put in that function, not at bottom here
  println("load spec from JSON");
  File dir  = new File(dataPath("data_selections"));
   selectInput("Select a dataset selection file (JSON):", "loadSelectedSpec",dir);
   while (spec==null){
     delay(10000);
     println("Waiting for dataset selection file to be chosen");
   }
}
void loadSelectedSpec(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("Loading " + selection.getAbsolutePath());
    spec=loadSpecFromJSON(selection.getAbsolutePath());
    spec.init();
    set_stackNameLookupFolderOption_from_filenameLookupFolder();
  }
  rebuildGuiSpecControls=true;
}

// This method sets a specGui element (stackNameLookupFolderOption) from a spec field (imageFolderPath)
// So normally this should be run automatically to ensure gui reflects current spec state.
// But risk of race condition or loop with stackNameLookupFolder_textbox
// So this needs to be run carefully - only at start and spec load
void set_stackNameLookupFolderOption_from_filenameLookupFolder(){
  if (spec.filenameLookupFolder.equals(spec.imageFolderPath())){
     if (!stackNameLookupFolderOption.getState(0)) stackNameLookupFolderOption.activate(0);
    } else if (spec.filenameLookupFolder.equals(spec.objectFolderPath(0,0))) {
      if (!stackNameLookupFolderOption.getState(1)) stackNameLookupFolderOption.activate(1);
    } else stackNameLookupFolderOption.deactivateAll(); //else if (!stackNameLookupFolderOption.getState(2)
    //stackNameLookupFolderOption.activate(2); // would like to do this without activating the folder select tool
}

void saveSpec(){
  println("save spec to JSON");
  File dir  = new File(dataPath("data_selections")); // TODO: better solution than hardcoded path here
   selectOutput("Select a dataset specification file (JSON):", "saveSpecToSelectedFile",dir);
}
void saveSpecToSelectedFile(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("Saving " + selection.getAbsolutePath());
    spec.saveToJSON(selection.getAbsolutePath());
  }
}  

void launch(){
  // The point is to run launch_vis, but running here directly causes an error with ControlP5
  // because (I think) it involves removing the current controls within a child process of one of those controls
  // So instead set runMode to trigger launch_vis from draw() 
  spec.saveToJSON(dataPath("data_selections/lastLoaded.json"));
  runMode="loadData";
}


// ********************************** toggles: loadImageData loadObjectData loadTracks  **********************************

void loadImageData_toggle(){
  spec.loadImageData = !spec.loadImageData;
  println(spec.loadImageData);
  spec.init();
}
void loadObjectData_toggle(){
  spec.loadObjectData = !spec.loadObjectData;
  spec.init();
}
void loadTracks_toggle(){
  spec.loadTracks = !spec.loadTracks;
  spec.init();
}

void generateBlendedImages_toggle(){
  spec.generateBlendedImages = !spec.generateBlendedImages;
  spec.init();
}
void loadProbMaps_toggle(){
  spec.loadProbMaps = !spec.loadProbMaps;
  spec.init();
}

// ************************************************** set_pathAndName textBox & lookupPath button (GUIspec) **************************************************
void set_pathAndName(String fullPath){ 
  fullPath = fullPath.replace('\\','/') ;
  println(fullPath);
  int p=fullPath.lastIndexOf("/");
  if (p==-1){
    return;
  }
  spec.rootPath = fullPath.substring(0,p+1);
  spec.datasetFolder = fullPath.substring(p+1);
  spec.datasetName = spec.datasetFolder;
  if (stackNameLookupFolderOption.getState(0)){
    spec.filenameLookupFolder = spec.imageFolderPath();
  } else
  if (stackNameLookupFolderOption.getState(1)){
    spec.filenameLookupFolder = spec.objectFolderPath(0,0);
  }
  spec.init();
}

void lookupPath(){
  File dir  = new File(spec.rootPath); 
   selectFolder("Select data folder:", "resetPath",dir);
   spec.init();
}
void resetPath(File fileSelection){ 
  set_pathAndName(fileSelection.getAbsolutePath());
  spec.init();
}


// ************************************************** set_title text (GUIspec) **************************************************
void set_title(String nm){
  spec.datasetName = nm;
}


void set_maxChannelPercentageThreshold(String st){
  Integer v = int(st);
  if (st.equals(v.toString()) && v>=0 && v<=100){
    spec.maxChannelPercentageThreshold=v;
  } else {
    maxChannelPercentageThreshold_textbox.setText(Integer.toString(spec.maxChannelPercentageThreshold));
  }
}


// ********************************** timeStep selection (GUIspec) **********************************

// *********** Add_TimeStep text (GUIspec) *************
// timeSteps should be arrayList for the following, but manual 1 at a time adding and removal allows for this inefficiency
// prefer not to break pattern of using arrays in DatasetSpec
void Add_TimeStep(String input){
  Integer val = int(input);
  // println(input+" "+val);
  if (input.equals(val.toString())){
    println("Adding timeStep" + val);
    int[] ts = new int[spec.timeSteps.length+1];
    for (int i=0;i<spec.timeSteps.length;i++){ts[i]=spec.timeSteps[i];}
    ts[ts.length-1]=val;
    spec.timeSteps=ts;
    spec.init();

    return;
  }
  String[] splitInput = input.split("-");
  if (splitInput.length!=2) return;
  splitInput[0] = splitInput[0].trim();
  splitInput[1] = splitInput[1].trim();
  Integer v0=int(splitInput[0]);
  Integer v1=int(splitInput[1]);
  if (splitInput[0].equals(v0.toString()) && splitInput[1].equals(v1.toString()) && v0<=v1){
    println("Adding timeSteps" + v0+" to "+v1);
    int[] ts = new int[spec.timeSteps.length+1+v1-v0];
    for (int i=0;i<spec.timeSteps.length;i++){ts[i]=spec.timeSteps[i];}
    for (Integer i=v0;i<=v1;i++){
      ts[spec.timeSteps.length-v0+i]=i;
      //removeTimeStep.addItem(i.toString(),true);
    }
    spec.timeSteps=ts;
    spec.init();
    
    return;
    
  }
}

// ****** clear_timeSteps (reset) button (GUIspec) ******
void clear_timeSteps(){
  spec.timeSteps = new int[0];
  spec.init();
  
}


void set_stackNameLookupFolder(String nm){
  stackNameLookupFolderOption.deactivateAll();
  spec.filenameLookupFolder = nm;
  spec.init();
}

// *************** setting parameters for parsing time step number from stack file name ****************

void set_filenameStackNumberMethod_from_radiobutton(){
  if (filenameStackNumberMethod_radio.getState(0)){
    spec.filenameStackNumberMethod = "alphanumeric";
    } else if (filenameStackNumberMethod_radio.getState(1)){
      spec.filenameStackNumberMethod = "between_substrings";
    }
    spec.init();
}
void filename_parse_startString(String nm){
  if (spec.filenameStackNumberStartStopSubstrings == null || spec.filenameStackNumberStartStopSubstrings.length != 2){
    spec.filenameStackNumberStartStopSubstrings = new String[2];
  }
  spec.filenameStackNumberStartStopSubstrings[0] = nm;
  spec.init();
}
void filename_parse_endString(String nm){
  if (spec.filenameStackNumberStartStopSubstrings == null || spec.filenameStackNumberStartStopSubstrings.length != 2){
    spec.filenameStackNumberStartStopSubstrings = new String[2];
  }
  spec.filenameStackNumberStartStopSubstrings[1] = nm;
  spec.init();
}


// ************************************************** segmentations (GUIspec) **************************************************

void Add_Segmentation_Folder(){
  String s1 = New_Segmentation_Folder == null ? null : New_Segmentation_Folder.getText();
  if (s1==null || s1.equals("")) return;
  String s2 = New_Segmentation_Name == null ? null : New_Segmentation_Name.getText();
  if (s2==null || s2.equals("")) s2=s1;
  //println(s1+","+s2);
  spec.segFolders.add(s1);
  spec.segNames.add(s2);  
  spec.init();
}

void Clear_Segmentation_Text(){
  New_Segmentation_Folder.setText("");
  New_Segmentation_Name.setText("");
}






// ********************************** object data **********************************

void Add_Object_Folder(){
  String s1 = New_Object_Folder == null ? null : New_Object_Folder.getText();
  if (s1==null || s1.equals("")) return;
  String s2 = New_Track_Filename == null ? null : New_Track_Filename.getText();
  String s3 = New_Object_Name == null ? null : New_Object_Name.getText();
  if (s3==null || s3.equals("")) s3=s1;
  spec.objectfolders.add(s1);
  spec.trackNames.add(s2);
  spec.objectAndTrackNames.add(s3);
  spec.init();
}

void Clear_Object_Text(){
  New_Object_Folder.setText("");
  New_Track_Filename.setText("");
  New_Object_Name.setText("");
}


// this is very clunky, but don't seem to have access to arraylist sort, or arraylist <-> array conversions
void Add_Remove_Class(String input){
  Integer val = int(input);
  if (!input.equals(val.toString())){return;}
  boolean seenIt = false;
  ArrayList<Integer> lst = new ArrayList<Integer>();//Arrays.asList()
  for (int i : spec.objectClasses){
    if (i==val){seenIt=true;} else {lst.add(i);}
  }
  if (!seenIt){
    lst.add(val);
    if (!spec.parentClasses.containsKey(val)){spec.parentClasses.put(val,-1);}
    if (!spec.objectThresholds.containsKey(val)){spec.objectThresholds.put(val,0.0);}
    if (!spec.classColours.containsKey(val)){spec.classColours.put(val,color(255));}
    if (!spec.meshColours.containsKey(val)){spec.meshColours.put(val,color(255));}
    if (!spec.trackColours.containsKey(val)){spec.trackColours.put(val,color(255));}
  }
  int[] arr = new int[lst.size()];
  for (int i=0;i<lst.size();i++){
    arr[i] = lst.get(i);
  }
  spec.objectClasses = sort(arr);
  rebuildGuiSpecControls=true;
}

// ********************************** relative paths **********************************

void imageFolderSubfolder_textchange(String nm){
  spec.imageFolderSubfolder=nm;
}
void segsSubfolder_textchange(String nm){
  spec.segsSubfolder=nm;
}
void probMapsSubfolder_textchange(String nm){
  spec.probMapsSubfolder=nm;
}

// ************************************************ CUSTOM CONTROLLER CLASSES *******************
// TODO: move most code gui code into this form (non-urgent)
// constructor should be called on first gui loop iteration; it draws the controls. Then setText (etc) should be called on each iteration to ensure consistency of control
// with underlying data; eventHandler must be called in the method controlEvent to check if one of its controls has been triggered; the string handlerNameGroup just has to 
// be unique across controls so that the control events can be distinguished by controlP5

class FloatArrayControl{
  float[] vals;
  String handlerNameGroup;
  Textfield[] buttons;
  
  FloatArrayControl(float[] vals_,String handlerNameGroup_,int posX, int posY, int buttonWidth,int buttonHeight,int buttonGap, ControlFont cf){
    vals=vals_;
    handlerNameGroup=handlerNameGroup_;
    buttons=new Textfield[vals.length];
    for (int i=0;i<vals.length;i++){
      buttons[i] = cp5.addTextfield(handlerNameGroup+"_"+i) //
                         .setPosition(posX+i*(buttonWidth+buttonGap),posY)
                         .setSize(buttonWidth,buttonHeight)
                         .setFont(cf)
                         .setFocus(false)
                         .setCaptionLabel("")
                         .setAutoClear(false)
                         ;
    }
  }
  
  void show(boolean visible){
    for (int i=0;i<vals.length;i++){
      if (visible){
        buttons[i].show();
      } else {
        buttons[i].hide();
      }
    }
  }
  
  void setText(){
    for (int i=0;i<vals.length;i++){
      if (!buttons[i].isFocus()){buttons[i].setText(Float.toString(vals[i]));}
    }
  }
  
   void eventHandler(ControlEvent theEvent){
    if (!theEvent.isController()){return;}
    String ev = theEvent.getController().toString();
    for (int i=0;i<vals.length;i++){
      if (!ev.equals(handlerNameGroup+"_"+i+" [Textfield]")){continue;}
      Float v = float(buttons[i].getText());
      if (v.isNaN()){
          buttons[i].setText(Float.toString(vals[i]));
        } else {
          vals[i]=v;
        }
    }
   }
}


class IntMapControl{
  HashMap<Integer,Integer> vals;
  int[] classes;
  String handlerNameGroup;
  Textfield[] buttons;
  
  IntMapControl(HashMap<Integer,Integer> vals_,int[] classes_,String handlerNameGroup_,int posX, int posY, int buttonWidth,int buttonHeight,int buttonGap, ControlFont cf){
    vals=vals_;
    classes=classes_;
    handlerNameGroup=handlerNameGroup_;
    buttons=new Textfield[classes.length];
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      buttons[clIndex] = cp5.addTextfield(handlerNameGroup+"_"+cl) //
                         .setPosition(posX+clIndex*(buttonWidth+buttonGap),posY)
                         .setSize(buttonWidth,buttonHeight)
                         .setFont(cf)
                         .setFocus(false)
                         .setCaptionLabel("")
                         .setAutoClear(false)
                         ;
    }
  }
  void remove(){
    if (classes==null){return;}
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      buttons[clIndex].remove();
      //cp5.remove(handlerNameGroup+"_"+cl);
    }
  }
  
  void setText(){
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      if (!buttons[clIndex].isFocus()){buttons[clIndex].setText(Integer.toString(vals.get(classes[clIndex])));}
    }
  }
  
  void eventHandler(ControlEvent theEvent){
    if (!theEvent.isController()){return;}
    String ev = theEvent.getController().toString();
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      if (ev.equals(handlerNameGroup+"_"+cl+" [Textfield]")){
        Integer v = int(buttons[clIndex].getText());
        if (buttons[clIndex].getText().equals(v.toString())){
          vals.put(cl,v);
        } else {
          buttons[clIndex].setText(Integer.toString(vals.get(cl)));
        }
      }
    }
  }
}

// this is almost identical to IntMapControl, wish I had proper generics
// tricky bit is parsing string and checking it is correct
class IntFloatMapControl{
  HashMap<Integer,Float> vals;
  int[] classes;
  String handlerNameGroup;
  Textfield[] buttons;
  
  IntFloatMapControl(HashMap<Integer,Float> vals_,int[] classes_,String handlerNameGroup_,int posX, int posY, int buttonWidth,int buttonHeight,int buttonGap, ControlFont cf){
    vals=vals_;
    classes=classes_;
    handlerNameGroup=handlerNameGroup_;
    buttons=new Textfield[classes.length];
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      buttons[clIndex] = cp5.addTextfield(handlerNameGroup+"_"+cl) //
                         .setPosition(posX+clIndex*(buttonWidth+buttonGap),posY)
                         .setSize(buttonWidth,buttonHeight)
                         .setFont(cf)
                         .setFocus(false)
                         .setCaptionLabel("")
                         .setAutoClear(false)
                         ;
    }
  }
  
  void remove(){
    if (classes==null){return;}
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      buttons[clIndex].remove();
    }
    buttons=null;
  }
  
  void setText(){
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      if (!buttons[clIndex].isFocus()){buttons[clIndex].setText(vals.get(classes[clIndex]).toString());}
    }
  }
  
  void eventHandler(ControlEvent theEvent){
    if (!theEvent.isController()){return;}
    String ev = theEvent.getController().toString();
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      if (ev.equals(handlerNameGroup+"_"+cl+" [Textfield]")){
        Float v = float(buttons[clIndex].getText());
        if (v.isNaN()){
          buttons[clIndex].setText(vals.get(cl).toString());
        } else {
          vals.put(cl,v);
        }
      }
    }
  }
}

class ColorControl{
  HashMap<Integer,Integer> cols;
  int[] classes;
  String handlerNameGroup;
  Textfield[][] buttons;

  ColorControl(HashMap<Integer,Integer> cols_,int[] classes_,String handlerNameGroup_,int posX, int posY, int buttonWidth,int buttonHeight,int buttonGap, ControlFont cf){
    cols=cols_;
    classes=classes_;
    handlerNameGroup=handlerNameGroup_;
    buttons=new Textfield[4][classes.length];
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      for (int ch=0;ch<4;ch++){
        buttons[ch][clIndex] = cp5.addTextfield(handlerNameGroup+"_"+cl+"_"+ch) //
                           .setPosition(posX+clIndex*(buttonWidth+buttonGap),posY+ch*(buttonHeight))
                           .setSize(buttonWidth,buttonHeight)
                           .setFont(cf)
                           .setFocus(false)
                           .setCaptionLabel("")
                           .setAutoClear(false)
                           ;
      }
    }
  }
  
  void remove(){
    if (classes==null){return;}
    for (Textfield[] col : buttons){
      for (Textfield b : col){
        b.remove();
      }
    }
  }
  
  void setTextAndColor(){
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      int c = cols.get(cl);
      int textCol = maxContrastColor(c); // brightness(c) > 127? 0 : color(255);
      for (int ch=0;ch<4;ch++){
        if (!buttons[ch][clIndex].isFocus()){
          buttons[ch][clIndex].setText(Integer.toString( c >> 8*((2-ch) % 4) & 0xFF));
          // if (!buttons[cl][ch].isFocus()){buttons[cl][ch].setText(Integer.toString(round(ch==0?red(c):(ch==1?green(c):(c==2?blue(c):alpha(c))))));} // should do the same, but this slower
          buttons[ch][clIndex].setColorBackground(c); // setColorBackground,setColorCursor, setColorActive?
          buttons[ch][clIndex].setColor(textCol);
        }
      }
    }
  }
  
  void setChannel(int cl,int ch, int newVal){
    int c = cols.get(cl);
    int[] x = new int[]{round(red(c)),round(green(c)),round(blue(c)),round(alpha(c))};
    x[ch] = newVal;
    cols.put(cl,color(x[0],x[1],x[2],x[3]));
  }
  
  void eventHandler(ControlEvent theEvent){
    if (!theEvent.isController()){return;}
    String ev = theEvent.getController().toString();
    for (int clIndex=0;clIndex<classes.length;clIndex++){
      int cl = classes[clIndex];
      for (int ch=0; ch<4; ch++){
        if (ev.equals(handlerNameGroup+"_"+cl+"_"+ch+" [Textfield]")){
          Integer v = int(buttons[ch][clIndex].getText());
          if (buttons[ch][clIndex].getText().equals(v.toString()) && v>=0 && v<=255){
            setChannel(cl,ch,v);
            buttons[ch][clIndex].setColorBackground(cols.get(cl));
            buttons[ch][clIndex].setColor(maxContrastColor(cols.get(cl)));//  ;brightness(cols.get(cl)) > 127? 0 : color(255)
          } else {
            buttons[ch][clIndex].setText(Integer.toString( cols.get(cl) >> 8*((2-ch) % 4) & 0xFF));
          }
        }
      }
    }
  }
  
}
