
// simple data class; create one instance containing all data to be displayed
// uses ImageData and Track objects, which include more methods
// current state (controlling what to show and how) stored in GUI

class Dataset {
  
  // metadata  ****************************************
  
  String title=null;
  ArrayList<String> stackNames; // these are filenames
  ArrayList<String> segmentationNames;
  ArrayList<String> objectAndTrackNames;
  int[] objectClasses;

  int[] timeSteps; // retain time step keys in persistant order 
  int sliceCount=0; 
  float[] voxelDim;
  boolean hasProbMaps;
  boolean hasBlendedImages;
  
  float[] positionOffSetForMultiTimesteps; 
  
  HashMap<Integer,Integer> segmentationColours;
  
  
  // image and object data ****************************************
  
  HashMap<Integer,ImageData> imageDatasetsByTimeStep; 
  HashMap<Integer, HashMap<Integer, Track>>[][] trackSetsByClass; 
  // each value of imageDatasetsByTimeStep contains the complete image and object information for one time step, except for tracks
  // trackSetsByClass has a parallel data structure to the ImageData.objectSetsByClass values, but covers all time steps:
  //  an array indexed by segmentation then object representation version, which gives a dictionary lookup by class
  // track information is mapped onto the objects in setup, as well as being used directly in the display
 
  // Each full track file is loaded even if the main data is only loaded for some of the time steps.
  // this has no consequence except for a small cost in load time and memory use
  
  
  HashMap<Integer, HashMap<Integer, Track>> tracksByClass() {   
    // gives 
    if (currentObjectSet == null || trackSetsByClass == null || currentClassifiedImage == null) {return(null);}
    int currentCI = (int) currentClassifiedImage.getValue();
    int k = (int) currentObjectSet.getValue();
    if (trackSetsByClass.length <= currentCI){
      return(null);
    }
    if (k<0 || k>trackSetsByClass[currentCI].length) {return(null);}
    return(trackSetsByClass[currentCI][k]);
  }
  
  
}
