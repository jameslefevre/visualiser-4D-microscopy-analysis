// a few minor methods that do not depend on any of my other code

String[] repeatLength1StringArray(String[] shortArray,int newLength){
  //print("test");print(shortArray);print(newLength);
  assert shortArray.length==1;
  String[] arr = new String[newLength];
  for (int ii=0;ii<newLength;ii++){
    arr[ii]=shortArray[0];
  }
  return(arr);
}

int[] intRangeInclusive(int n1,int n2){
  int[] r = new int[n2-n1+1];
  for (int ii=n1; ii<=n2;ii++){
    r[ii-n1]=ii; 
  }
  return(r);
}
ArrayList<String> arrayToArrayList_String(String[] sa){
  ArrayList<String> al = new ArrayList<String>();
  for (String st : sa) al.add(st);
  return al;
}

String timeStamp(){
  return(year() + "-" + nf(month(),2) + "-" + nf(day(),2) + "T" + nf(hour(),2) + ":" + nf(minute(),2) + ":" + nf(second(),2));
}


int maxContrastColor(int c){
  //return(color(red(c)>127?0:255,green(c)>127?0:255,blue(c)>127?0:255)); // bit ditracting?
  return(red(c)+blue(c)+green(c)>375 ? 0 : color(255));
}
