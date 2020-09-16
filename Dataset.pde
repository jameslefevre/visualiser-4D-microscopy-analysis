
// simple data class; create one instance containing all data to be displayed
// uses ImageData and Track objects, which include more methods
// current state (controlling what to show and how) stored in GUI



class Dataset {
  
  // metadata /  etc ****************************************
  
  String title=null;
  ArrayList<String> stackNames; // these are filenames, but could be made to be different (new setup code)
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
  //   Integer c = color(2,3,4,0);

  
  // image and object data ****************************************
  
  HashMap<Integer,ImageData> imageDatasetsByTimeStep; 
  // following track data structure parallel to ImageData.objectSetsByClass, but operates across full time range
  // The time steps included in tracks may not be loaded 
  HashMap<Integer, HashMap<Integer, Track>>[][] trackSetsByClass; 
  // key1= class, key2= trackId (to retain option of fast lookup by id); indices are CI and object set
  HashMap<Integer, HashMap<Integer, Track>> tracksByClass() {   
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
