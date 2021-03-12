import processing.opengl.*;
import peasy.*;
import controlP5.*; // documentation: http://www.sojamo.de/controlP5

float drawScalingFactor =  2;
PVector lightDirection = new PVector(0,0,1);

String runMode = "setSpec"; // "setSpec", "loadData", "waitingForData",  "launchVis", "running"
// set to "setSpec" to run data specification GUI, or "loadData" to bypass and launch with the default spec
int timeStepCounter = 0;

ArrayList<String> saveGUIscreenshotAs = new ArrayList<String>(); // allows Visualiser process to trigger GUI screenshot(s) next time it is complete; should usually be empty

ControlP5 cp5;
DatasetSpec spec;
Dataset dataset = new Dataset();
Visualiser visualiser;


void settings(){
  size( 800, 900);
}
void setup(){
  
  frame.setResizable(true);
  // optionally bypass specGUI by setting runMode="lauchVis" above, and either hard code spec below or skip direct to loading spec from file
  spec = loadSpecFromJSON(dataPath("")+"/data_selections/lastLoaded.json");
  if (runMode.equals("setSpec")){
    specGui(true); // sets up the gui for selecting the data specification
    return;
  } 
  if (spec==null) {loadSpec();} // if spec not loaded above from hardcoded path, run the spec selector to get the user to choose (same routine that can be run from specGUI)
}

void launch_vis(){
  println("SETUP STARTED at " + second());
  println("Initialising GUI");
  surface.setSize(400,800);
  gui(true);
  println("GUI setup complete");
  
  println("Initialising Visualiser and launching in separate process");
  String[] args = {"Visualiser"};
  visualiser = new Visualiser();
  PApplet.runSketch(args, visualiser);
}

// forward keyboard input to visualiser, allowing key commands to work when either window is active
// exception for printscreen command - causes crash when forwarded
void keyPressed(){
  if (runMode.equals("setSpec") || visualiser==null) return;
  if (key=='p') {return;}
  visualiser.key = key;
  visualiser.keyCode = keyCode;
  visualiser.keyPressed();
}
void keyReleased(){
  if (runMode.equals("setSpec") || visualiser==null) return;
  if (key=='p') {return;}
  visualiser.key = key;
  visualiser.keyCode = keyCode;
  visualiser.keyReleased();
}

// This is the main loop for the primary process and the control window (visualiser window is a child process)
// state tracked by runMode variable, which transitions down the following list; entry point may be setSpec or loadData

// setSpec: 
//    expects DatasetSpec spec initialised to default value, interface set up for selecting and editing spec (via call specGui(true) )
//    text on the data selection gui is updated each loop since values may change (gui controllers are self-managed)
//    runMode is changed to loadData when the launch button is clicked
// loadData:
//    expects DatasetSpec spec to be set to final value, no expectation on interface state
//    runs for a single iteration: cleans up any existing controls, starts data loading in a separate thread, and sets runMode=waitingForData
// waitingForData:
//    Expects no existing controls and dataSetup running in separate thread
//    draws progress bars using counters updated by the data loading process
//    runMode is flipped to launchVis at the conclusion of the dataSetup method
// launchVis:
//    Expects dataset object to be complete, containing all image data, and no existing controls
//    runs for a single iteration: the visualiser is started and the primary window is set up with visualiser controls, then runMode is set to running
// running:
//    expects visualiser subprocess and controller gui set up
//    text on controller gui is updated each loop since values may change (gui controllers are self-managed)
//    final state

void draw() {
  timeStepCounter++;
  ArrayList<String> paths = saveGUIscreenshotAs;
  saveGUIscreenshotAs = new ArrayList<String>();
  // need to avoid risk of concurrent modification issue, since visualiser process may append to saveGUIscreenshotAs while I'm doing the screenshot(s)
  for (String path : paths){saveFrame(path);}
  
  switch(runMode){
    case "setSpec":
      specGui(false);
      break;
    case "loadData":
      //println("Loading data");
      if (cp5 !=null) {
        cp5.dispose();
        println("Ran dispose() on spec GUI");
      }
      runMode = "waitingForData";
      thread("dataSetup"); // sets runMode="launchVis" when complete
      break;
    case "waitingForData":
      //println("waitingForData");
      loadProgressDisplay();
      break;
    case "launchVis":
      println("launchVis");
      launch_vis();
      runMode = "running";
      break;
    case "running":
      // println("running");
      gui(false);
      break;
    default:
      println("runMode not recognised !!!");
      
  }
 
}
