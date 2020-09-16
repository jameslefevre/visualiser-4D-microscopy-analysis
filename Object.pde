class OBJECT{
  int id;
  int classNum;
  
  PVector centre;
  int voxels;
  double volume;
  double surfaceArea;
  
  TrackNode trackNode;
  
  Skeleton skel; 
  ObjectMesh objectMesh;
  
  HashMap<OBJECT, Integer> adjacencies;
  
  OBJECT(int _id,int _classNum,int _voxels){
    id = _id;
    classNum = _classNum;
    voxels = _voxels;
    adjacencies = new HashMap<OBJECT, Integer>();
    // skel = new Skeleton();
  }
  
  OBJECT clone(){
    OBJECT ob = new OBJECT(id,classNum,voxels);
    ob.centre = centre;
    
    ob.centre = centre;
    ob.volume = volume;
    ob.surfaceArea = surfaceArea;
    ob.trackNode = trackNode;
    ob.skel = skel;
    ob.objectMesh = objectMesh;
    ob.adjacencies = adjacencies;   
    return(ob);
  }
  
  boolean isVisible(){
    if (!classesDisplayedObject.getState("c" + classNum)) {
      return false;
    }
    if (filterObjects.getState("Size") && filterObjectsByClass.getState("Size-" + classNum) && (volume < spec.objectThresholds.get(classNum)) ) {
      return false;
    }
    if (filterObjects.getState("Tracked") && filterObjectsByClass.getState("Tracked-" + classNum)&& trackNode==null ) {
      return false;
    }
    return true;
  }
}

// object functions

class Skeleton{
  Table table;
  Skeleton(){
    table = new Table();
  }
  Skeleton(String filePath){
    if (filePath != null){
      table = loadTable(filePath, "header");
    }
  }
  Skeleton(TableRow r, float[] scaleFactor){
    ArrayList<TableRow> rs = new ArrayList<TableRow>();
    scaleSkelRow(r,scaleFactor); 
    rs.add(r);
    table = new Table(rs);
  }
  void addSkelRow(TableRow r, float[] scaleFactor){
    scaleSkelRow(r,scaleFactor);
    table.addRow(r);
  }
  
  void scaleSkelRow(TableRow r, float[] scaleFactor){
    r.setFloat("V1 x",r.getFloat("V1 x")*scaleFactor[0]);
    r.setFloat("V1 y",r.getFloat("V1 y")*scaleFactor[1]);
    r.setFloat("V1 z",r.getFloat("V1 z")*scaleFactor[2]);
    r.setFloat("V2 x",r.getFloat("V2 x")*scaleFactor[0]);
    r.setFloat("V2 y",r.getFloat("V2 y")*scaleFactor[1]);
    r.setFloat("V2 z",r.getFloat("V2 z")*scaleFactor[2]);
  }
 
  
  void printInfo(){
    if (table==null){
      println("No skeleton object loaded");
      return;
    }
    // https://processing.org/reference/Table.html
    println("number of branch segments = " + table.getRowCount());
    table.print();
  }
}

// MESH stuff


class ObjectMesh{
  float[]  vertices;
  int[] triangles;
  float[] normalDotLight;
  
  ObjectMesh(ArrayList<Float> vertexList, ArrayList<Integer> tris, PVector lightSourceDirection){
    vertices = new float[vertexList.size()];
    triangles = new int[tris.size()];
    normalDotLight = new float[tris.size()/3];
    for (int ii =0; ii<vertexList.size(); ii++){
      vertices[ii] = vertexList.get(ii);
    }
    for (int ii =0; ii<tris.size(); ii++){
      triangles[ii] = tris.get(ii);
    }
    if (lightSourceDirection==null){
      for (int ii=0;ii<normalDotLight.length;ii++){
        normalDotLight[ii]=1;
      }
    } else {
      for (int ii=0;ii<normalDotLight.length;ii++){
        PVector v1 = new PVector(vertices[3*triangles[ii*3]],vertices[3*triangles[ii*3]+1],vertices[3*triangles[ii*3]+2]);
        PVector v2 = new PVector(vertices[3*triangles[ii*3+1]],vertices[3*triangles[ii*3+1]+1],vertices[3*triangles[ii*3+1]+2]);
        PVector v3 = new PVector(vertices[3*triangles[ii*3+2]],vertices[3*triangles[ii*3+2]+1],vertices[3*triangles[ii*3+2]+2]);
        v1 = v1.sub(v3);
        v2 = v2.sub(v3);     
        PVector norm = v1.cross(v2);
        norm.normalize();
        normalDotLight[ii]=norm.dot(lightSourceDirection);
      }
    }
  }
  
  // for debugging / sanity check
  //PVector meanVertexPosition(){
  //  PVector mean = new PVector(0,0,0);
  //  for (PVector v : vertices){
  //    mean.add(v);
  //  }
  //  mean.div(vertices.size());  
  //  return(mean);
  //}
}
