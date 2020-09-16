
// raw, segmented, prob, blended ; objects, tracks
boolean[] image_load_check = {false,false,false,false};
int[] data_load_counts = new int[6]; // for progress bars

void dataSetup(){
  dataset.title =spec.datasetName;
  dataset.stackNames = spec.stackNames;
  dataset.segmentationNames = spec.segNames;
  dataset.objectAndTrackNames = spec.objectAndTrackNames;
  //dataset.sliceCount = spec.numSlices();
  dataset.voxelDim = spec.voxelDim;
  dataset.hasProbMaps = spec.loadProbMaps;
  dataset.hasBlendedImages= spec.generateBlendedImages;
  dataset.objectClasses = spec.objectClasses;
  dataset.positionOffSetForMultiTimesteps = spec.positionOffSetForMultiTimesteps;
  
  dataset.imageDatasetsByTimeStep = new HashMap<Integer,ImageData>();
  dataset.timeSteps = sort(spec.timeSteps);
  for (int imNum : dataset.timeSteps) {
    dataset.imageDatasetsByTimeStep.put(imNum,new ImageData(dataset));
  }
  // imageSetup(); // launches new threads
  if (spec.loadImageData){
    println("Initialising image loading and preparation in " + (spec.loadProbMaps ? 3 : 2) + " separate threads"); 
    thread("loadRawImages");
    thread("loadClassifiedImages");
    if (spec.loadProbMaps){
      thread("loadProbabilityMapImages");
    } else {
      image_load_check[2] =true;
    }
      
    if (spec.generateBlendedImages){
      println("checking completion of raw image load before blending with classified images");
      while (!image_load_check[0] || !image_load_check[1]){
        delay(100);
      }
      thread("blendRawAndClassifiedImages_all");
    } else {
      image_load_check[3] =true;
    }
  } else {
    image_load_check = new boolean[]{true,true,true,true};
  }
  
  if (spec.loadObjectData) {
    loadObjectInformation();
    print("Objects loaded: timeSteps = "); for (int t:dataset.timeSteps){print(t+" ");} ; println();
    if (spec.loadTracks) loadTracks(spec);
    
  }
  
  
  
  while (!image_load_check[0] || !image_load_check[1] || !image_load_check[2] || !image_load_check[3]){
    println("waiting for image loading completion, status " + image_load_check[0] + "," + 
    image_load_check[1] + "," + image_load_check[2] + "," + image_load_check[3]);

    delay(1000);
  }
  
  // aggregate segmentation pixel color counts across time; this is to allow hiding of channels
  dataset.segmentationColours = new HashMap<Integer,Integer>();
  for (ImageData imDat : dataset.imageDatasetsByTimeStep.values()){
    if (imDat.pixelColourCounts==null){continue;}
    for (int c : imDat.pixelColourCounts.keySet()){
      if (!dataset.segmentationColours.containsKey(c)){
        dataset.segmentationColours.put(c,imDat.pixelColourCounts.get(c));
      } else {
        dataset.segmentationColours.put(c,dataset.segmentationColours.get(c)+imDat.pixelColourCounts.get(c));
      }
    }
  }
  for (int c : dataset.segmentationColours.keySet()){println(c," : ",dataset.segmentationColours.get(c));} 
  ArrayList<Integer> killColours = new ArrayList<Integer>(); killColours.add(0); // black pixels are always set to transparent
  for (int c : dataset.segmentationColours.keySet()){
    if (dataset.segmentationColours.get(c) < ignoreSegmentationPixelCountsBelowThisThreshold){killColours.add(c);}
    // this is a nasty hack to deal with stray pixels that really shouldn't be there
  }
  for (int c : killColours){dataset.segmentationColours.remove(c);}
  
  // delay(5000);
  
    println("switching runMode to launchVis");
    runMode = "launchVis";
} // end main data loading method

  
// UNSAFE: going to assume format correct/ as expected at first, no checking
  // assume vertices come before the faces which use them
  HashMap<Integer, ObjectMesh> getObjectMeshes(String pth, float[] voxelDim, boolean unifiedVertexNumbering, PVector lightDirection) {
    String[] lines = loadStrings(pth);
    println("there are " + lines.length + " lines in mesh file");
    HashMap<Integer, ObjectMesh> mshs = new HashMap<Integer, ObjectMesh>();
    // ObjectMesh currentMesh = new ObjectMesh();
    // ArrayList<PVector> vertexList = new ArrayList<PVector>();
    int vertexOffset = 1;
    ArrayList<Float> vertices =  new ArrayList<Float>();
    ArrayList<Integer> tris =  new ArrayList<Integer>();
    Integer objectId = null;
    for (int i = 0; i < lines.length; i++) {
      String[] tokens = split(lines[i], ' ');
      if (tokens[0].equals("g")) {
        if (objectId != null){
          mshs.put(objectId, new ObjectMesh(vertices,tris, lightDirection));
        }
        vertices =  new ArrayList<Float>();
        tris =  new ArrayList<Integer>();   
        objectId = int(split(tokens[1], "_")[1]);
        
        if (unifiedVertexNumbering){
          vertexOffset = vertexOffset + vertices.size()/3;
        }
      } else if (tokens[0].equals("v")) {
        vertices.add(float(tokens[1])*voxelDim[0]);
        vertices.add(float(tokens[2])*voxelDim[1]);
        vertices.add(float(tokens[3])*voxelDim[2]);
        
      } else if (tokens[0].equals("f")) {
        tris.add(int(tokens[1])-vertexOffset);
        tris.add(int(tokens[2])-vertexOffset);
        tris.add(int(tokens[3])-vertexOffset);
      }
    }
    if (objectId != null){
          mshs.put(objectId, new ObjectMesh(vertices,tris, lightDirection));
        }
    return(mshs);
  }
  
  
    // TRACK RELATED STUFF
 
  void loadTracks(DatasetSpec sp){
    println("loading track information");
    int numberSegs = sp.segNames.size();
    dataset.trackSetsByClass = new HashMap[numberSegs][] ; 
    for (int segNumber = 0; segNumber<numberSegs; segNumber++) {
      int numberObSets = sp.objectAndTrackNames.size();
      dataset.trackSetsByClass[segNumber] = new HashMap[numberObSets];
      for (int objectSetNum = 0; objectSetNum < numberObSets; objectSetNum ++) {
        HashMap<Integer, HashMap<Integer, Track>> tracksByClass = new HashMap<Integer, HashMap<Integer, Track>>();
        //println(dataset.trackSetsByClass.length, " / ", dataset.trackSetsByClass[segNumber].length, " ; ", segNumber, " / ", objectSetNum);
        //println(sp.trackTimeOffsets.length);
        dataset.trackSetsByClass[segNumber][objectSetNum] = tracksByClass;
        HashMap<Integer,TrackNode> nodeLookup = new HashMap<Integer,TrackNode>();
        String trackNodePath = sp.trackPath(segNumber,objectSetNum);
        println("loading track info " + trackNodePath);
        if ( !(new File(trackNodePath)).exists()){
          println("track data not found !!!");
          continue;
        }
        Table trackNodeTable = loadTable(trackNodePath, "header, tsv");  
        if (trackNodeTable==null) continue;
        // println("loaded table");
        for (TableRow r : trackNodeTable.rows()) {
          // println(r==null," ",tracksByClass==null," ",dataset.imageDatasetsByTimeStep==null," ",sp.voxelDim==null," ",sp.trackTimeOffsets==null);
          TrackNode tn = new TrackNode(r, tracksByClass, dataset.imageDatasetsByTimeStep, segNumber,objectSetNum, sp.voxelDim, sp.trackTimeOffsets != null && sp.trackTimeOffsets.length>objectSetNum ? sp.trackTimeOffsets[objectSetNum] : null); // constructor adds Node to track, object references
          nodeLookup.put(tn.id,tn);
        }
        // println("Created nodes: ",nodeLookup.size());
        for (TrackNode tn : nodeLookup.values()){
          tn.addNodeReferences(nodeLookup,sp.voxelVolume());
        }
        // calculate parent tracks; 
        for (int classId : tracksByClass.keySet()){
          
          //int parentClass = -1;
          //for (int classIndex =0; classIndex<sp.objectClasses.length; classIndex++){
            //if (sp.objectClasses[classIndex]==classId){
              //parentClass=sp.parentClasses[classIndex];
              //break;
            //}
          //}
          println("get parent for class "+classId);
          int parentClass=sp.parentClasses.get(classId);
          if (parentClass<0){continue;}
          for (Track tr : tracksByClass.get(classId).values()){
            tr.addParentTrack(parentClass);
          }
        }
        data_load_counts[5]++;
      }
    }
  }

// *************** methods to run in separate threads *******************************************************************

void loadRawImages(){
  for (int imageNumber : dataset.timeSteps){
    if (spec.imageFolderPath(imageNumber) != null){
    dataset.imageDatasetsByTimeStep.get(imageNumber).loadPrepRawImage(spec,imageNumber);
    if (dataset.imageDatasetsByTimeStep.get(imageNumber).img != null){
    int numSlices = dataset.imageDatasetsByTimeStep.get(imageNumber).img.im.length;
    if (numSlices>dataset.sliceCount) dataset.sliceCount = numSlices;
    }
    println("Loaded and alpha-masked primary image " + imageNumber);
    }
    data_load_counts[0]++;
  }
  image_load_check[0] =true;
}

void loadClassifiedImages(){
  for (int imageNumber : dataset.timeSteps){
    boolean loaded = dataset.imageDatasetsByTimeStep.get(imageNumber).loadPrepClassifiedImages(spec,imageNumber);
    if (loaded) {
      ImageStack[] ic = dataset.imageDatasetsByTimeStep.get(imageNumber).imgCl;
      if (ic == null) continue;
      for (int k =0; k<ic.length; k++){
        if (ic[k]==null || ic[k].im == null) continue;
        int numSlices = ic[k].im.length;
        if (numSlices>dataset.sliceCount) dataset.sliceCount = numSlices;
      }
      
    println("Loaded and alpha-masked classified images " + imageNumber);
  }
  data_load_counts[1]++;
  }
  image_load_check[1] =true;
}

void blendRawAndClassifiedImages_all(){
  
  for (int imageNumber : dataset.timeSteps){
      boolean bl = dataset.imageDatasetsByTimeStep.get(imageNumber).blendRawAndClassifiedImages();
      println("blending images for time " + imageNumber + ": ");
      println(bl ? "Succeeded" : "Failed");
      data_load_counts[3]++;
    }
    image_load_check[3] =true;
}

void loadProbabilityMapImages(){
  for (int imageNumber : dataset.timeSteps){
    dataset.imageDatasetsByTimeStep.get(imageNumber).loadPrepProbMapImages(spec,imageNumber);
    if (dataset.imageDatasetsByTimeStep.get(imageNumber) == null) continue;
    ImageStack[] ic = dataset.imageDatasetsByTimeStep.get(imageNumber).imgProbMap;
    if (ic == null) continue;
      for (int k =0; k<ic.length; k++){
        if (ic[k]==null) continue;
        int numSlices = ic[k].im.length;
        if (numSlices>dataset.sliceCount) dataset.sliceCount = numSlices;
      }
    // println("Loaded and alpha-masked probability map images " + imageNumber);
    data_load_counts[2]++;
  }
    image_load_check[2] =true;
}

void loadObjectInformation(){
  for (int imageNumber : dataset.timeSteps){
    dataset.imageDatasetsByTimeStep.get(imageNumber).loadObjectInfo(spec,imageNumber);
    println("Loaded object information " + imageNumber);
    data_load_counts[4]++;
  }
  
}
