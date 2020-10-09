
// provide all information on how to load a dataset (what files to load, where they are)
// mostly data class, plus logic for loading and saving from JSON

class DatasetSpec{
  /*
  Keep names for use in GUI separate from subfolder names, although they may often be the same.
  */
  //String rootPath="D:/image_data/visualiser/";
  String rootPath="/home/james/image_data/visualiser/";
  int[] timeSteps = {}; 
  HashMap<Integer,Integer> timestepPos = new HashMap<Integer,Integer>();
  String datasetName;
  String datasetFolder;
  String imageFolderSubfolder = "deconv";
  ArrayList<String> segNames= new ArrayList<String>();
  ArrayList<String> segFolders=new ArrayList<String>();
  // {objectAndTrackNames, objectfolders, trackNames must be same length}
  ArrayList<String> objectAndTrackNames=new ArrayList<String>();
  ArrayList<String> objectfolders=new ArrayList<String>(); 
  ArrayList<String> trackNames=new ArrayList<String>();
  int[] trackTimeOffsets=null; // option to add const offset to time values in each track file (to deal with off-by-one issues)
  String probMapsSubfolder="probability_maps";
  String segsSubfolder="segmented";
  ArrayList<String> stackNames;
  int slicePadNumber=4;
  float[] voxelDim = {1.04,1.04,2.68};
  float[] objectScaling = {1.04,1.04,2.68};
  float[] meshScaling = {1.04,1.04,2.68};
  float[] skeletonScaling = {0.001,0.001,0.001};
  int[] objectClasses = {1,2,3,4};
  HashMap<Integer,Integer> parentClasses = intMap(new int[]{1,2,3,4},new int[]{-1,4,4,1});
  boolean loadImageData=true;
  boolean loadObjectData=true;
  boolean loadTracks=true;
  
  String filenameStackNumberMethod="between_substrings"; // "alphanumeric"
  String[] filenameStackNumberStartStopSubstrings = {"-t","-e"};
  String filenameLookupFolder;

  // image display settings
  float[] positionOffSetForMultiTimesteps = {-70,0,120}; // {50,0,120}; // used for act4 etc 
  float[] logGammaRange = {-1.5,1.5,0.7}; //last number is initial value
  boolean generateBlendedImages = false;
  boolean loadProbMaps = true;
  int maxChannelPercentageThreshold=20; // if max non-background class prob is below this value, we make voxel fully transparent
  
  // object display settings
  // values are selected from arrays using class id as index, so arrays need to have length max(classId)+1
  // typically class 0 is background so first value in eash array is dummy
 
  HashMap<Integer,Integer> meshColours = intMap(new int[]{1,2,3,4},new int[]{color(79,200,130),color(200,10,10),color(10,10,200),color(180,10,180)});
  HashMap<Integer,Integer> classColours = intMap(new int[]{1,2,3,4},new int[]{color(79,255,130,150),color(255,10,10,200),color(10,10,255,220),color(255,10,255,200)});
  // I was supporting an alternate color scheme for end and branch points, leaving this here in case I want them back:
  //HashMap<Integer,Integer> meshColoursHighlight = intMap(new int[]{1,2,3,4},new int[]{color(150,250,130),color(250,100,10),color(100,100,200),color(200,100,200)});  
  //HashMap<Integer,Integer> classColoursHighlight = intMap(new int[]{1,2,3,4},new int[]{color(150,250,130,250),color(250,100,10,250),color(100,100,200,250),color(200,100,200,250)});
  HashMap<Integer,Float> objectThresholds = intFloatMap(new int[]{1,2,3,4},new float[]{5000.0,75.0,500.0,500.0}); 
  HashMap<Integer,Integer> trackColours = intMap(new int[]{1,2,3,4},new int[]{color(200, 200, 10),color(200, 200, 10),color(200, 200, 10),color(200, 200, 10)});
  
  // convenience function used to define maps above:
  HashMap<Integer,Integer> intMap(int[] ks, int[] vs){
    HashMap<Integer,Integer> mp = new HashMap<Integer,Integer>();
    int n = ks.length<vs.length ? ks.length : vs.length;
    for (int i=0; i<n; i++){
      mp.put(ks[i],vs[i]);
    }
    return mp;
  }
  HashMap<Integer,Float> intFloatMap(int[] ks, float[] vs){
    HashMap<Integer,Float> mp = new HashMap<Integer,Float>();
    int n = ks.length<vs.length ? ks.length : vs.length;
    for (int i=0; i<n; i++){
      mp.put(ks[i],vs[i]);
    }
    return mp;
  }
 
 
  float voxelVolume(){return voxelDim[0]*voxelDim[1]*voxelDim[2];}
  
  String stackName(int stackNum){
    return(stackNames.get(timestepPos.get(stackNum)));
  }
  String imageFolderPath(){
    return rootPath+datasetFolder+"/"+imageFolderSubfolder+"/";
  }
  String imageFolderPath(int stackNum){
    return rootPath+datasetFolder+"/"+imageFolderSubfolder+"/"+stackName(stackNum)+"/";
  }
  String segFolderPath(int segNumber, int stackNum){
    return rootPath+datasetFolder+"/"+segFolders.get(segNumber)+"/"+segsSubfolder+"/"+stackName(stackNum)+"/";
  }
  String probFolderPath(int segNumber, int stackNum){
    return rootPath+datasetFolder+"/"+segFolders.get(segNumber)+"/"+probMapsSubfolder+"/"+stackName(stackNum)+"/";
  }
  String objectFolderPath(int segNumber, int objectNum){
    if (segFolders==null || segFolders.size()<segNumber+1 || objectfolders==null || objectfolders.size()<objectNum+1 ){return null;}
    return(rootPath+datasetFolder+"/"+segFolders.get(segNumber)+"/"+objectfolders.get(objectNum)+"/");
  }
  String objectFolderPath(int segNumber, int objectNum, int stackNum){
    return(rootPath+datasetFolder+"/"+segFolders.get(segNumber)+"/"+objectfolders.get(objectNum)+"/"+stackName(stackNum)+"/");
  }
  String trackPath(int segNumber, int objectNum){
    if (trackNames.size()<objectNum){return(null);}
    return(rootPath+datasetFolder+"/"+segFolders.get(segNumber)+"/"+objectfolders.get(objectNum)+"/"+trackNames.get(objectNum)+".csv");
  }
  float[][] scalingParams(){
    return(new float[][]{voxelDim,objectScaling,meshScaling,skeletonScaling});
  }
  
  // couldn't see how to avoid this boilerplate without a java import plus non-trivial code
  
  JSONObject exportToJSONobject(){
    JSONObject j = new JSONObject();
    j.setString("rootPath",rootPath);
    j.setJSONArray("timeSteps",intArrayToJSON(timeSteps));
    j.setString("datasetName",datasetName);
    j.setString("datasetFolder",datasetFolder);
    j.setString("imageFolderSubfolder",imageFolderSubfolder);
    j.setJSONArray("segNames",stringArrayListToJSON(segNames));
    j.setJSONArray("segFolders",stringArrayListToJSON(segFolders));
    j.setJSONArray("objectAndTrackNames",stringArrayListToJSON(objectAndTrackNames));
    j.setJSONArray("objectfolders",stringArrayListToJSON(objectfolders));
    j.setJSONArray("trackNames",stringArrayListToJSON(trackNames));
    if (trackTimeOffsets!=null){j.setJSONArray("trackTimeOffsets",intArrayToJSON(trackTimeOffsets));}
    j.setString("probMapsSubfolder",probMapsSubfolder);
    j.setString("segsSubfolder",segsSubfolder);
    //j.setJSONArray("stackNames",stringArrayToJSON(stackNames));   
    j.setInt("slicePadNumber",slicePadNumber);
    j.setJSONArray("voxelDim",floatArrayToJSON(voxelDim));
    j.setJSONArray("objectScaling",floatArrayToJSON(objectScaling));
    j.setJSONArray("meshScaling",floatArrayToJSON(meshScaling));
    j.setJSONArray("skeletonScaling",floatArrayToJSON(skeletonScaling));
    //j.setFloat("skeletonScalingFactor",skeletonScalingFactor);
    j.setJSONArray("objectClasses",intArrayToJSON(objectClasses));
    j.setBoolean("loadImageData",loadImageData);
    j.setBoolean("loadObjectData",loadObjectData);
    j.setBoolean("loadTracks",loadTracks);
    j.setString("filenameStackNumberMethod",filenameStackNumberMethod);
    j.setJSONArray("filenameStackNumberStartStopSubstrings",stringArrayToJSON(filenameStackNumberStartStopSubstrings));
    j.setString("filenameLookupFolder",filenameLookupFolder);
    j.setJSONObject("parentClasses",intIntMapToJSON(parentClasses));
    j.setJSONArray("positionOffSetForMultiTimesteps",floatArrayToJSON(positionOffSetForMultiTimesteps));
    j.setJSONArray("logGammaRange",floatArrayToJSON(logGammaRange));
    j.setBoolean("generateBlendedImages",generateBlendedImages);
    j.setBoolean("loadProbMaps",loadProbMaps);
    j.setInt("maxChannelPercentageThreshold",maxChannelPercentageThreshold);
    j.setJSONObject("classColours",intIntMapToJSON(classColours));
    j.setJSONObject("meshColours",intIntMapToJSON(meshColours));
    j.setJSONObject("trackColours",intIntMapToJSON(trackColours));
    j.setJSONObject("objectThresholds",intFloatMapToJSON(objectThresholds));
    return(j);
  }
  void saveToJSON(String pth){
    JSONObject j = exportToJSONobject();
    saveJSONObject(j, pth,"compact");
  }

  void importFromJSON(JSONObject j ){
    if (!j.isNull("rootPath")){rootPath = j.getString("rootPath");}
    if (!j.isNull("timeSteps")){timeSteps = j.getJSONArray("timeSteps").getIntArray();}
    if (!j.isNull("datasetName")){datasetName = j.getString("datasetName");}
    if (!j.isNull("datasetFolder")){datasetFolder = j.getString("datasetFolder");}
    if (!j.isNull("imageFolderSubfolder")){imageFolderSubfolder = j.getString("imageFolderSubfolder");}
    if (!j.isNull("segNames")){segNames = JSON_to_StringArrayList(j.getJSONArray("segNames"));}
    if (!j.isNull("segFolders")){segFolders = JSON_to_StringArrayList(j.getJSONArray("segFolders"));}  
    if (!j.isNull("objectAndTrackNames")){objectAndTrackNames = JSON_to_StringArrayList(j.getJSONArray("objectAndTrackNames"));}
    if (!j.isNull("objectfolders")){objectfolders = JSON_to_StringArrayList(j.getJSONArray("objectfolders"));}
    if (!j.isNull("trackNames")){trackNames = JSON_to_StringArrayList(j.getJSONArray("trackNames"));}
    if (!j.isNull("trackTimeOffsets")){trackTimeOffsets = j.getJSONArray("trackTimeOffsets").getIntArray();}
    if (!j.isNull("probMapsSubfolder")){probMapsSubfolder = j.getString("probMapsSubfolder");}
    if (!j.isNull("segsSubfolder")){segsSubfolder = j.getString("segsSubfolder");}
    //if (!j.isNull("stackNames")){stackNames = j.getJSONArray("stackNames").getStringArray();}
    if (!j.isNull("slicePadNumber")){slicePadNumber = j.getInt("slicePadNumber");}
    if (!j.isNull("voxelDim")){voxelDim = j.getJSONArray("voxelDim").getFloatArray();}
    if (!j.isNull("objectScaling")){objectScaling = j.getJSONArray("objectScaling").getFloatArray();}
    if (!j.isNull("meshScaling")){meshScaling = j.getJSONArray("meshScaling").getFloatArray();}
    if (!j.isNull("skeletonScaling")){skeletonScaling = j.getJSONArray("skeletonScaling").getFloatArray();}
    //if (!j.isNull("skeletonScalingFactor")){skeletonScalingFactor = j.getFloat("skeletonScalingFactor");}
    if (!j.isNull("objectClasses")){objectClasses = j.getJSONArray("objectClasses").getIntArray();}
    if (!j.isNull("loadImageData")){loadImageData = j.getBoolean("loadImageData");}
    if (!j.isNull("loadObjectData")){loadObjectData = j.getBoolean("loadObjectData");}
    if (!j.isNull("loadTracks")){loadTracks = j.getBoolean("loadTracks");}
    if (!j.isNull("filenameStackNumberMethod")){filenameStackNumberMethod = j.getString("filenameStackNumberMethod");}
    if (!j.isNull("filenameStackNumberStartStopSubstrings")){filenameStackNumberStartStopSubstrings = j.getJSONArray("filenameStackNumberStartStopSubstrings").getStringArray();}
    if (!j.isNull("filenameLookupFolder")){filenameLookupFolder = j.getString("filenameLookupFolder");}
    if (!j.isNull("parentClasses")){parentClasses = JSONtoIntIntMap(j.getJSONObject("parentClasses"));}
    if (!j.isNull("positionOffSetForMultiTimesteps")){positionOffSetForMultiTimesteps = j.getJSONArray("positionOffSetForMultiTimesteps").getFloatArray();}
    if (!j.isNull("logGammaRange")){logGammaRange = j.getJSONArray("logGammaRange").getFloatArray();}
    if (!j.isNull("generateBlendedImages")){generateBlendedImages = j.getBoolean("generateBlendedImages");}
    if (!j.isNull("loadProbMaps")){loadProbMaps = j.getBoolean("loadProbMaps");}
    if (!j.isNull("maxChannelPercentageThreshold")){maxChannelPercentageThreshold = j.getInt("maxChannelPercentageThreshold");}
    if (!j.isNull("classColours")){classColours = JSONtoIntIntMap(j.getJSONObject("classColours"));}
    if (!j.isNull("meshColours")){meshColours = JSONtoIntIntMap(j.getJSONObject("meshColours"));}
    if (!j.isNull("trackColours")){trackColours = JSONtoIntIntMap(j.getJSONObject("trackColours"));}
    if (!j.isNull("objectThresholds")){objectThresholds = JSONtoIntFloatMap(j.getJSONObject("objectThresholds"));}
  }
  void loadFromJSON(String pth){
     File f = new File(dataPath(pth)); 
     if (f.exists()) { 
       JSONObject j = loadJSONObject(pth);
       importFromJSON(j);
     } else {
       println("Could not load JSPN data selection file:");
       println(pth +"\n");
     }
  }
  
  void init(){
    timestepPos = new HashMap<Integer,Integer>();
    for (int ii=0;ii<timeSteps.length;ii++){
      timestepPos.put(timeSteps[ii],ii);
    }
    if (datasetName == null){datasetName = datasetFolder;}
    if (filenameLookupFolder==null){filenameLookupFolder = imageFolderPath();}
    if (filenameStackNumberMethod.equals("alphanumeric")){
      stackNames = getStackNamesFromAlphanumericOrder(filenameLookupFolder,timeSteps);
    } else if (filenameStackNumberMethod.equals("between_substrings")){
      stackNames = getStackNamesBetweenStrings(filenameLookupFolder,timeSteps,filenameStackNumberStartStopSubstrings);
    } else {
      println("!!! Did not load stackNames -  filenameStackNumberMethod not recognised - value "+filenameStackNumberMethod+" !!!");
    }
    voxelDim = ensureFloatTripleDefault1(voxelDim);
    objectScaling = ensureFloatTripleDefault1(objectScaling);
    meshScaling = ensureFloatTripleDefault1(meshScaling);
    skeletonScaling = ensureFloatTripleDefault1(skeletonScaling);
  }
  
}


// ***** utlity methods for dataset spec

float[] ensureFloatTripleDefault1(float[] x){
  if (x != null && x.length==3){return x;}
  float[] y = new float[]{1.0,1.0,1.0};
  if (x != null && x.length>0){y[0]=x[0];}
  if (x != null && x.length>1){y[1]=x[1];}
  if (x != null && x.length>2){y[2]=x[2];}
  return y;
}


JSONObject intIntMapToJSON(HashMap<Integer,Integer> mp){
  JSONObject jo = new JSONObject();
  for (Integer k : mp.keySet()){
    jo.setInt(k.toString(),mp.get(k));
  }
  return(jo);
}
HashMap<Integer,Integer> JSONtoIntIntMap(JSONObject jo){
  HashMap<Integer,Integer> hm = new HashMap<Integer,Integer>();
  for (Object k : jo.keys()){
    //String sk = (String) k;
    Integer ik = Integer.parseInt((String) k);
    hm.put(ik,jo.getInt((String) k));
  }
  return hm;
}
JSONObject intFloatMapToJSON(HashMap<Integer,Float> mp){
  JSONObject jo = new JSONObject();
  for (Integer k : mp.keySet()){
    jo.setFloat(k.toString(),mp.get(k));
  }
  return(jo);
}
HashMap<Integer,Float> JSONtoIntFloatMap(JSONObject jo){
  HashMap<Integer,Float> hm = new HashMap<Integer,Float>();
  for (Object k : jo.keys()){
    //String sk = (String) k;
    Integer ik = Integer.parseInt((String) k);
    hm.put(ik,jo.getFloat((String) k));
  }
  return hm;
}


JSONArray intArrayToJSON(int[] arr){
  JSONArray ja = new JSONArray();
  for (int ii=0;ii<arr.length;ii++){
      ja.setInt(ii,arr[ii]);
    }
    return(ja);
}
JSONArray stringArrayToJSON(String[] arr){
  JSONArray ja = new JSONArray();
  for (int ii=0;ii<arr.length;ii++){
      ja.setString(ii,arr[ii]);
    }
    return(ja);
}
JSONArray floatArrayToJSON(float[] arr){
  JSONArray ja = new JSONArray();
  for (int ii=0;ii<arr.length;ii++){
      ja.setFloat(ii,arr[ii]);
    }
    return(ja);
}

JSONArray integerArrayListToJSON(ArrayList<Integer> arr){
  JSONArray ja = new JSONArray();
  for (int ii=0;ii<arr.size();ii++){
      ja.setInt(ii,arr.get(ii));
    }
    return(ja);
}
JSONArray stringArrayListToJSON(ArrayList<String> arr){
  JSONArray ja = new JSONArray();
  for (int ii=0;ii<arr.size();ii++){
      ja.setString(ii,arr.get(ii));
    }
    return(ja);
}
JSONArray floatArrayListToJSON(ArrayList<Float> arr){
  JSONArray ja = new JSONArray();
  for (int ii=0;ii<arr.size();ii++){
      ja.setFloat(ii,arr.get(ii));
    }
    return(ja);
}

ArrayList<String> JSON_to_StringArrayList(JSONArray js){
  String[] sa = js.getStringArray();
  ArrayList<String> al = new ArrayList<String>();
  for (String st : sa) al.add(st);
  return al;
}

// methods for setting up DatasetSpec

DatasetSpec loadSpecFromJSON(String path){
  spec = new DatasetSpec();
  spec.loadFromJSON(path);
  spec.init();
  return(spec);
}

ArrayList<String> getStackNamesBetweenStrings(String folderPath, int[] stackNums, String[] bookendStrings){
  assert(bookendStrings.length==2);
  ArrayList<String> stackNames = new ArrayList<String>(); // new String[stackNums.length];
  for (int ii=0;ii<stackNums.length;ii++) stackNames.add(null);
  IntList stacks = new IntList(stackNums);
  File file = new File(folderPath);
  
  String[] filenames = file.list();
  if (filenames==null) return stackNames;
  for (String fn : filenames){
    //fn = fn.split("[.]")[0];
    println(fn);
    String[] fn_sp1 = fn.split(bookendStrings[0]);
    if (fn_sp1.length<2){continue;}
    fn_sp1 = fn_sp1[1].split(bookendStrings[1]);
    if (fn_sp1.length<2){continue;}
    int stNum = int(fn_sp1[0]);
    if (stacks.hasValue(stNum)){
      for (int ii=0;ii<stackNums.length;ii++){
        if (stackNums[ii]==stNum){
          // stackNames[ii] = fn;
          stackNames.set(ii,fn);
        }
      }
    }
  } 
  return(stackNames);
} 
  
ArrayList<String> getStackNamesFromAlphanumericOrder(String folderPath, int firstStackNum, int lastStackNum){
  File file = new File(folderPath);
  String[] filenames = sort(file.list());
  if (lastStackNum>=filenames.length){
    println("!!! Requested stacks " + firstStackNum + " - " + lastStackNum + ", but only " + filenames.length + " files in " + folderPath);
    println(" returning stacks within the specified range, based on alphanumeric order of names");
  }
  ArrayList<String> stackNames = new ArrayList<String>();
  for (int ii=0;ii<min(lastStackNum-firstStackNum+1,filenames.length - firstStackNum);ii++){
    stackNames.add(filenames[ii+firstStackNum].split("[.]")[0]);
  }
  return(stackNames);
}
ArrayList<String> getStackNamesFromAlphanumericOrder(String folderPath, int[] stackNums){
  println("getStackNamesFromAlphanumericOrder");
  ArrayList<String> stackNames = new ArrayList<String>();
  if (folderPath==null){println("getStackNamesFromAlphanumericOrder - folderPath==null"); return(stackNames);}
  if (stackNums==null){println("getStackNamesFromAlphanumericOrder - stackNums==null"); return(stackNames);}
  File file = new File(folderPath);
  String[] filenames = file.list();
  if (filenames==null){println("getStackNamesFromAlphanumericOrder - filenames==null"); return(stackNames);}
  filenames = sort(filenames); 
  //String[] stackNames = new String[stackNums.length];
  for (int sNum : stackNums){
    if (sNum>=0 && sNum<filenames.length){
      stackNames.add(filenames[sNum].split("[.]")[0]);
      //println(stackNames[ii]);
    } else stackNames.add(null);
  }
  return(stackNames);
}
