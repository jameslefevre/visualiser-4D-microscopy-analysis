/*
ImageData contains all image and object data for a single time step/stack, including references from objects to the containing tracks (which of course are not time-specific).
Each ImageData instance is expected to be contained in the main Dataset object, and is linked back via the parentDataset field
This is used to access metadata, including 3 key size parameters: the number of segmentation models (segmentationNames.length = numSegs), the number of object/track analyses applied to each segmentation (objectAndTrackNames.length = numObs), and the number of slices (sliceCount).
Thus the data is fully rectangular in layout, but not all data needs to be present (null data objects should be handled safely). The data compenents are
- Single image stack for original image
- segmented and prob map stack for each segmentation
- For each seg/object combination, a collection of Objects arranged in a hashmap by class then id (global for the current time step / ImageData object)

In the case where we consider multiple tracks based on the same object description, the only difference in the ImageData object will be in Object.trackNode; 
as long as they are listed consecutively in the DatasetSpec, the loading routine detects this and clones objects (all prior to associating with tracks): 
this should lead to sharing of contained objects, in particular the expensive ObjectMesh.
*/

class ImageData {
  Dataset parentDataset;
  ImageStack img;
  ImageStack imgAdjusted; // img with gamma adjustment
  ImageStack[] imgCl;
  ImageStack[] imgBlended;
  ImageStack[] imgProbMap;
  HashMap<Integer,Integer> pixelColourCounts;
  
  HashMap<Integer, HashMap<Integer, OBJECT>>[][] objectSetsByClass;
  // key1= class, key2= (global) id; indices are CI and object set

  HashMap<Integer, HashMap<Integer, OBJECT>> objectsByClass() {   
    if (currentObjectSet == null || objectSetsByClass == null || currentClassifiedImage == null) {return(null);}
    int currentCI = (int) currentClassifiedImage.getValue();
    if (currentCI < 0){return(null);}
    int k = (int) currentObjectSet.getValue();
    if (k<0 || k>objectSetsByClass[currentCI].length) {return(null);}
    return(objectSetsByClass[currentCI][k]);
  }
  
  ImageStack currentStack() {
    // should this return null when !showImage ? For now, ignore  
    int idm = round(imageDisplayMode.getValue());
    if (idm<0) return null;
    if (idm==0){
      if (showGammaTransform && imgAdjusted != null) return imgAdjusted;
      return img;
    }
    int cci = currentClassifiedImage == null ? 0 : (int) round(currentClassifiedImage.getValue());
    if (cci<0) return null;
    if (idm==1){
      if (imgCl == null || imgCl.length <= cci) return null;
      return imgCl[cci];
    }
    if (idm==2){
      if (imgProbMap == null || imgProbMap.length <= cci) return null;
      return imgProbMap[cci];
    }
    if (idm==3){
      if (imgBlended == null || imgBlended.length <= cci) return null;
      return imgBlended[cci];
    }
    return null;
  }

  void calculateGammaAdjustedImage(float gamma) {
    if (gamma<=0 || img==null) {
      return;
    }
    imgAdjusted = img.clone();
    imgAdjusted.applyGammaTransform(gamma);
    println("applied gamma transform " + timeStamp());
    imgAdjusted.alphaMask();
  }

  void changeColourAlphaClassifiedImages(int col, int alpha) {
    for (ImageStack img : imgCl) {
      // switchColourToTransparent(img,col);
      img.changeColourAlpha(col, alpha);
    }
  }

  // ************************************** imageData loading methods **************************************

  ImageData() {
  }
  ImageData(Dataset ds) {
    parentDataset = ds;
  }

  void loadPrepRawImage(DatasetSpec sp, int imageNumber) {
    String imgPath = spec.imageFolderPath(imageNumber);
    if (imgPath == null) {
      return;
    }
    img = loadImageStack(imgPath,sp.slicePadNumber);
    println("loaded raw image "  + timeStamp());
    // calculateGammaAdjustedImage(inverseGamma);
    if (img!=null){img.alphaMask();}
  }


  boolean loadPrepClassifiedImages(DatasetSpec sp, int imageNumber){
    int numSegs = sp.segNames.size();
    imgCl = new ImageStack[numSegs];
    pixelColourCounts = new HashMap<Integer,Integer>();
    for (int ii=0; ii<numSegs; ii++) {
      String pth = sp.segFolderPath(ii,imageNumber);
      if (pth!=null && (new File(pth)).exists()) {
        imgCl[ii] = loadImageStack(pth,sp.slicePadNumber);
        for (PImage sl : imgCl[ii].im){      
          countPixelColours(sl,pixelColourCounts);
          // print("slice "+(tempCounter++)+":  "); for (int ky : pixelColourCounts.keySet()) print(ky + ":" + pixelColourCounts.get(ky)+"; "); println();     
        }
        imgCl[ii].alphaMaskMethod = "binary";
        imgCl[ii].alphaMask();
        println("Alpha-masked " + sp.stackName(imageNumber) +", seg "+  sp.segNames.get(ii) + " at " + second());
      } else {
        println("No segmented image found at " + pth);
        return(false);
      }
    }
    return(true);
  }
  void loadPrepProbMapImages(DatasetSpec sp, int imageNumber) {
    int numSegs = sp.segNames.size();
    imgProbMap = new ImageStack[numSegs];
    for (int ii=0; ii<numSegs; ii++) {
      String pth = sp.probFolderPath(ii,imageNumber);
      if (pth!=null && (new File(pth)).exists()) {
        imgProbMap[ii] = loadImageStack(pth,sp.slicePadNumber);
        imgProbMap[ii].alphaMaskMethod = "maxChannel";
        imgProbMap[ii].alphaMask();
        println("Loaded and alpha-masked probability map for " + pth + " at " + second());
      } else {
         println("No probability map found for " + pth + " at " + second());
      }
    }
  }
 
  boolean blendRawAndClassifiedImages() {
    if (img==null || imgCl == null) {
      return false;
    }
    if (imgBlended == null) {
      imgBlended = new ImageStack[imgCl.length];
    }
    boolean completed = true;

    for (int ii=0; ii<imgCl.length; ii++) {
      if (imgCl[ii] == null) {
        completed = false;
        continue;
      }
      boolean allSlices = true;
      for (int jj=0; jj< imgCl[ii].im.length; jj++) {
        if (imgCl[ii].im[jj] == null) {
          allSlices = false;
          break;
        }
      }
      if (!allSlices) {
        completed = false;
        continue;
      }
      imgBlended[ii] = blendColourAndIntensity(imgCl[ii], img);
      imgBlended[ii].alphaMaskMethod = "maxChannel";
      imgBlended[ii].alphaMask();
      //println("Blended raw and classified images for " + imgClNames [ii]);
    }
    return completed;
  }
  
  void loadObjectInfo(DatasetSpec sp, int imageNumber) {
    println("loading object information");
    int numSegs = sp.segNames.size();
    println("numSegs = " + numSegs);
    objectSetsByClass = new HashMap[numSegs][];
    for (int segNumber = 0; segNumber<numSegs; segNumber++) {
      int numberObSets = sp.objectAndTrackNames.size();
      println("numberObSets = " + numberObSets);
      objectSetsByClass[segNumber] = new HashMap[numberObSets];
      for (int objectSetNum = 0; objectSetNum < numberObSets; objectSetNum ++) {
        HashMap<Integer, HashMap<Integer, OBJECT>> objectsByClass = new HashMap<Integer, HashMap<Integer, OBJECT>>();
        HashMap<Integer, OBJECT> objects = new HashMap<Integer, OBJECT>(); // temp structure so I can refer back to objects later by (global) id
        objectSetsByClass[segNumber][objectSetNum] = objectsByClass;
        String fldr = sp.objectFolderPath(segNumber,objectSetNum,imageNumber);
        
        // if object folder repeated, clone objects (with shared meshes, skeletons) to save time and space; expect tracks to differ for this to make sense
        if (objectSetNum>0 && fldr.equals(sp.objectFolderPath(segNumber,objectSetNum-1,imageNumber))){
          println("Repeated object folder: replicating object info");
          int cloneCount = 0;
          HashMap<Integer, HashMap<Integer, OBJECT>> objectsByClass_prev = objectSetsByClass[segNumber][objectSetNum-1];
          for (int classNum : objectsByClass_prev.keySet()){
            objectsByClass.put(classNum, new HashMap<Integer, OBJECT>());
            for (int id : objectsByClass_prev.get(classNum).keySet()){
              OBJECT ob = objectsByClass_prev.get(classNum).get(id).clone();
              objectsByClass.get(classNum).put(id,ob);
              cloneCount++;
            }
          }
          println("Cloned " + cloneCount + " objects");
          continue;
        }

        // now ready to populate objectsByClass (and objects) using data in fldr
        // first step: create objects from stats table with basic info; objects is used later to look up objects and add additional info
        println("loading object stats " + fldr + "objectStats.txt");
        if ( !(new File(fldr + "objectStats.txt")).exists()){
          println("no object stats found");
          continue;
        }
        Table objectStats = loadTable(fldr + "objectStats.txt", "header, tsv");      
        for (TableRow r : objectStats.rows()) {
          int classNum = r.getInt("class");
          int id = r.getInt("id");
          int voxels = r.getInt("voxels");
          OBJECT ob = new OBJECT(id, classNum, voxels);
          ob.volume = (double) voxels;
          ob.centre = new PVector(
            sp.objectScaling[0] * r.getFloat("x"), 
            sp.objectScaling[1] * r.getFloat("y"), 
            sp.objectScaling[2] * r.getFloat("z"));

          HashMap<Integer, OBJECT> classObjects;
          if (objectsByClass.containsKey(classNum)) {
            classObjects = objectsByClass.get(classNum);
          } else {
            classObjects = new HashMap<Integer, OBJECT>();
            objectsByClass.put(classNum, classObjects);
          }
          classObjects.put(id, ob); // classObjects.put(id, ob);
          objects.put(id, ob);
        }
        println("loaded " + objects.size() + " objects");

        // now add object adjacency info
        Table adj = loadTable(fldr + "objectAdjacencyTable.txt", "csv");
        for (TableRow r : adj.rows()) {
          int id1 = r.getInt(0);
          int id2 = r.getInt(1);
          int ad = r.getInt(2);
          //
          if (id1!=id2) {
            OBJECT ob1 = objects.get(id1);
            OBJECT ob2 = objects.get(id2);
            // println(id1 + " " + id2 + " " + ad);
            if ((ob1!=null) && (ob2!=null)) {
                ob1.adjacencies.put(objects.get(id2), ad);
                ob2.adjacencies.put(objects.get(id1), ad);
            }
          }
        }

        // now add skeletons
        
         String filename = fldr + "objectSkeletons.csv"; 
          File f = new File(dataPath(filename));
          if (f.exists()) {
            Table skeletons = loadTable(filename, "header");
            println("Loading object skeleton info from "+filename);
            // println("Contains " + skeletons.getRowCount() + " edges");
            int skelCnt = 0; int edgeCnt = 0;
            for (TableRow r : skeletons.rows()) {
              OBJECT ob = objects.get(r.getInt("Skeleton ID"));
              if (ob == null) {
                int trId = r.getInt("Skeleton ID");
                println("Tree with object id " + trId + " could not be mapped to an object");
                continue;
              }
              if (ob.skel == null) {
                ob.skel = new Skeleton(r,sp.skeletonScaling);
                skelCnt++; edgeCnt++;
              } else {
                ob.skel.addSkelRow(r,sp.skeletonScaling);
                edgeCnt++;
              }
            }
            println("Loaded " + edgeCnt + " edges over " + skelCnt + " object skeletons");
          }
          

        // now add meshes

        filename = fldr + "objectMeshes.obj";
        f = new File(dataPath(filename));
        if (f.exists()) {
          // println("no mesh file found at " + filename);
          println("loading meshes from " + filename);

          HashMap<Integer, ObjectMesh> meshes  = getObjectMeshes(filename, sp.meshScaling,false,lightDirection);
          if (meshes != null) {
            println("Loaded " + meshes.size() + " object meshes");
            for (int id : meshes.keySet()) {
              OBJECT ob = objects.get(id);
              if (ob == null) {
                println("!!! mesh object id " + id + " can not be mapped to an object");
                continue;
              }  
              ob.objectMesh = meshes.get(ob.id);
              
              // println("Object " + ob.id + " mesh has size " + ob.objectMesh.vertices.size() + "/" + ob.objectMesh.triangles.size() + " and position " + ob.objectMesh.meanVertexPosition());
            }
          }
        } else {
          println("No mesh data found at " + filename);
        }
      }
    }
  }
  
}
