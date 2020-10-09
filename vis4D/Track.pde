// simple classes used for track representation - Track and TrackNode
// contains constructors and a few miscellaneous methods
// methods to display tracks are not included - see Visualiser

class Track{
  int id;
  HashMap<Integer,ArrayList<TrackNode>> nodesByTime;
  Track parentTrack=null;
  ArrayList<Track> childTracks=new ArrayList<Track>();
  Track(int id_){
    id = id_;  
    nodesByTime = new HashMap<Integer,ArrayList<TrackNode>>();
  }
  void addNode(TrackNode tn){
    if (!nodesByTime.containsKey(tn.timeStep)){nodesByTime.put(tn.timeStep, new ArrayList<TrackNode>());}
    nodesByTime.get(tn.timeStep).add(tn);
  } 
  void addParentTrack(int parentClass){
    // requires TrackNode info to be populated
    HashMap<Track,Float> trackAds = new HashMap<Track,Float>();
    for (ArrayList<TrackNode> nds : nodesByTime.values()){
      for (TrackNode nd : nds){
        for (int adNum=0;adNum<nd.adjacent.size();adNum++){
          if (nd.adjacent.get(adNum).classNum!=parentClass){continue;}
          Track adTr = nd.adjacent.get(adNum).track;
          if (adTr==null){continue;}    
          float currentAd = trackAds.containsKey(adTr) ? trackAds.get(adTr) : 0.0;
          trackAds.put(adTr,currentAd+nd.adjacentNodeContact[adNum]);
        }
      }
    }
    float highestContact = -1;
    for (Track tr : trackAds.keySet()){
      if (trackAds.get(tr)>highestContact){
        parentTrack=tr;
        highestContact = trackAds.get(tr);
      } 
    }
    if (parentTrack!=null){
      parentTrack.childTracks.add(this);
    }
    
  }
}


class TrackNode{
  int id;
  int classNum;
  int timeStep;
  Track track;
  PVector centre;
  int voxels;
  ArrayList<OBJECT> objects;
  // next 3 fields are temporary to avoid reading through table twice; replaced by references to TrackNode objects once all initialised.
  String linkedPrev;
  String linkedNext;
  String adjacentNodes;
  ArrayList<TrackNode> preds;
  ArrayList<TrackNode> succs;
  ArrayList<TrackNode> adjacent;
  float[] adjacentNodeContact;
  float[] adjacentNodeRelativeNodeDistance;
  float[] adjacentNodeRelativeNodeContact;
  boolean branchOrEnd;
  //int[] branchesPrev;
  //int[] branchesNext;
  
  // as well as contructing the TrackNode, adds to tracksByClass and imageDatasetsByTimeStep (objectsByClass field within each ImageData object),
  // adding tracks as required and inserting bi-direction object references
  // assumes imageDatasetsByTimeStep is complete except for the Object.trackNode field which is added
  // references to other nodes (adjacent and linked in previous and following time step) cannot be added until all nodes initialised, so save info in text strings (to avoid re-reading data table)
  // and parse it in separate step (addNodeReferences, called from separate loop in dataInit)
  TrackNode(TableRow r, 
  HashMap<Integer, HashMap<Integer, Track>> tracksByClass, 
  HashMap<Integer,ImageData> imageDatasetsByTimeStep, 
  int ciNumber,
  int objectSetNum,
  float[] voxelDim,
  Integer timeOffset){   
    id = r.getInt("id");
    classNum = r.getInt("class");
    //classNum=3;
    timeStep =  r.getInt("timeStep");
    if (timeOffset != null ){timeStep+=timeOffset;}               
    voxels = r.getInt("voxels");
    centre = new PVector(
            voxelDim[0] * r.getFloat("x"), 
            voxelDim[1] * r.getFloat("y"), 
            voxelDim[2] * r.getFloat("z"));
    linkedPrev = r.getString("linkedPrev");
    linkedNext = r.getString("linkedNext");
    adjacentNodes = r.getString("adjacentNodes");
    adjacentNodeContact = float(split(r.getString("adjacentNodeContact"), ";"));
    branchOrEnd = r.getString("branchOrEnd").equals("TRUE");
    
    int [] objectIds = int(split(r.getString("objectIds"), ";"));
    //println("Creating TrackNode: completed initial load"); println("ciNumber = ",ciNumber, ", objectSetNum = ",objectSetNum, ", timeStep = ",timeStep);
    if (imageDatasetsByTimeStep.containsKey(timeStep)){
      if (imageDatasetsByTimeStep.get(timeStep).objectSetsByClass != null){
        HashMap<Integer, HashMap<Integer, OBJECT>> objectsByClass = imageDatasetsByTimeStep.get(timeStep).objectSetsByClass[ciNumber][objectSetNum];
        if (objectsByClass != null && objectsByClass.containsKey(classNum)) {
          HashMap<Integer, OBJECT> obs = objectsByClass.get(classNum);
          objects = new ArrayList<OBJECT>();
          for (int objectId : objectIds){
            println(objectId);
            if (obs.containsKey(objectId)){
              OBJECT ob = obs.get(objectId);
              objects.add(ob);
              ob.trackNode = this;
            }
          } 
        }
      }
    }
    //println("Linked TrackNode to objects");
    
    int trackId = r.getInt("trackId");
    if (!tracksByClass.containsKey(classNum)){tracksByClass.put(classNum,new HashMap<Integer, Track>());}
    if (!tracksByClass.get(classNum).containsKey(trackId)){tracksByClass.get(classNum).put(trackId,new Track(trackId));}
    track = tracksByClass.get(classNum).get(trackId);
    track.addNode(this);
  }
  void addNodeReferences(HashMap<Integer,TrackNode> nodeLookup, float voxelVolume){
    preds = new ArrayList<TrackNode>();
    succs = new ArrayList<TrackNode>();
    adjacent = new ArrayList<TrackNode>();
    if (!linkedPrev.equals("")){
      for (int id : int(split(linkedPrev,";"))){
        if (nodeLookup.containsKey(id)){preds.add(nodeLookup.get(id));}
      }
    }
    if (!linkedNext.equals("")){
      for (int id : int(split(linkedNext,";"))){
        if (nodeLookup.containsKey(id)){succs.add(nodeLookup.get(id));}
      }
    }
    for (int id : int(split(adjacentNodes,";"))){
      if (nodeLookup.containsKey(id)){adjacent.add(nodeLookup.get(id));}
    }
    // now calculate adjacentNodeRelativeNodeDistance, adjacentNodeRelativeNodeContact
    adjacentNodeRelativeNodeDistance = new float[adjacent.size()];
    adjacentNodeRelativeNodeContact = new float[adjacent.size()];
    for (int i=0;i<adjacent.size();i++){
      TrackNode adjNode = adjacent.get(i);
      // (4*pi/3)^(1/3) ~ 1.611992 is a correction factor for converting volume to radius
      if (adjNode!=null && centre!=null && adjNode.centre!=null){
        adjacentNodeRelativeNodeDistance[i]=(pow(voxels*voxelVolume,1.0/3.0)+pow(adjNode.voxels*voxelVolume,1.0/3.0))/(1.611992*centre.dist(adjNode.centre));
      }
      
      // Adjacencies are based on a 18-neighbour model; the adjacency count is the number of distinct pairs of neighbouring voxels under this def, that includes one from each object in question.
      // divide by 5 to get approximate contact area in voxel units
      // The surface area of a sphere of volume V is V^{2/3} * (36pi)^{1/3} ~ 4.835976 V^{2/3}
      // Thus the proportional contact estimate is (adjacency/5) / (V^{2/3} * (36pi)^{1/3}) = 1/(5*(36*pi)^{1/3}) * (adjacency/V^{2/3}) ~ 0.0413567 (adjacency/V^{2/3})
      if (adjNode!=null){
        adjacentNodeRelativeNodeContact[i]=0.0413567 * adjacentNodeContact[i] / pow(min(voxels,adjNode.voxels),2.0/3.0);
      }
    }
  }
}
