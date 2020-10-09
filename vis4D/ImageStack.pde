// Processing does not support 3D voxel images, so this is a limited implementation for our purposes
// does not e.g check/ensure same shape for each slice

// this tab includes additional functions on ImageStack and PImage at bottom, outside of class definition

// methods to display the ImageStack are not included - see Visualiser

class ImageStack {
  PImage[] im;
  int dimRotate = 0;
  String alphaMaskMethod = "intensity"; // intensity, maxChannel, binary
  
  void changeAxis(boolean posDirection){
    int h = im[0].height;
    int w = im[0].width;
    int s = im.length;
    if (posDirection){ 
      PImage[] imNew = new PImage[h];
      for (int z=0; z<h; z++){
        PImage sl = createImage(s, w, RGB);
        imNew[z]=sl;
        for (int x=0; x<s; x++){
          for (int y=0; y<w; y++){
            sl.set(x,y,im[x].get(y,z));
          }
        }
      }
      im = imNew;
      dimRotate = (dimRotate + 1) % 3;
    } else {
      PImage[] imNew = new PImage[w];
      for (int z=0; z<w; z++){
        PImage sl = createImage(h, s, RGB);
        imNew[z]=sl;
        for (int x=0; x<h; x++){
          for (int y=0; y<s; y++){
            sl.set(x,y,im[y].get(z,x));
          }
        }
      }
      im = imNew;
      dimRotate = (dimRotate + 2) % 3;
    }
  }
  
  void changeColourAlpha(int col, int alpha){
    if (im==null) return;
    for (PImage sl : im){
      if (sl==null) continue;
      sl.loadPixels();
      for (int i=0;i < sl.pixels.length;i++){
        int c = sl.pixels[i];
        if (c==col){
          sl.pixels[i] = color(red(c),green(c),blue(c),alpha);
        }
      }  
      sl.updatePixels();
    }
  }
  
  void alphaMask(){
    if (alphaMaskMethod.equals("intensity")) {
      alphaMaskIntensity(this);
    } else if (alphaMaskMethod.equals("maxChannel")) {
      alphaMaskMaxChannel(this);
    } else if (alphaMaskMethod.equals("binary")) {
      alphaMaskIntensity(getBinaryMaskStack());
    }  
  }
  
  void alphaMaskIntensity(ImageStack mask){
    if (im==null){return;}
    for (int z = 0 ; z < im.length ; ++z){
      if (im[z]!=null){
      im[z].mask(mask.im[z]);
      }
    }
  }
  void alphaMaskMaxChannel(ImageStack mask){
    if (im==null){return;}
    PImage msk;
    for (int z = 0 ; z < im.length ; ++z){
      msk = maxChannel(mask.im[z]);
      im[z].mask(msk);
    }
  }
  
  void applyGammaTransform(float gamma){
    int[] map = new int[256];
    for (int i=0; i<256; i++){
      map[i] = round(255.0*pow(i/255.0,gamma));
    }
    println(map);
    for (PImage i : im){
      if (i != null){
      applyIntensityTransform(i,map);
      } else {
        print("null");
      }
    }
  }

  ImageStack clone(){
    ImageStack st = new ImageStack();
    st.im = new PImage[im.length];
    for (int s=0; s<im.length; s++){
      if (im[s] != null){
      st.im[s] = im[s].copy();
      }
    }
    st.dimRotate = dimRotate;
    return(st);
  }
  
  ImageStack getBinaryMaskStack(){
    ImageStack bis = new ImageStack();
    bis.dimRotate = dimRotate;
    bis.im = new PImage[im.length];
    for (int z = 0 ; z < im.length ; ++z){
      bis.im[z] = getBinaryMask(im[z]);
    }
    return(bis);
  }
}

// separate functions which work with ImageStack

ImageStack blendColourAndIntensity(ImageStack colorStack, ImageStack intensityStack){
  if (colorStack.dimRotate != intensityStack.dimRotate){
    println("Cannot blend image stacks which are sliced on different axes");
    return(null);
  }
  int sliceNum = colorStack.im.length;
  println(sliceNum,intensityStack.im.length);
  assert sliceNum == intensityStack.im.length;
  PImage[] bl = new PImage[sliceNum];
  for (int s = 0 ; s < sliceNum ; s++){
    bl[s] = blendColourAndIntensity(colorStack.im[s],intensityStack.im[s]);
  }
  ImageStack st = new ImageStack();
  st.im=bl;
  st.dimRotate = colorStack.dimRotate;
  return(st);
}


ImageStack loadImageStack(String path, int slicePadNumber)
{
  File fl = new File(path);
  if (!(fl.exists()) || !fl.isDirectory()){
    return(null);
  }
  
  // print("Loading slice");
  
  ArrayList<PImage> imAL = new ArrayList<PImage>();
  
  int fileCount = fl.list().length;
  int nullCnt=0;
  for (int z=0; z<fileCount; z++){
    String n = path + "/slice" + nf(z,slicePadNumber) + ".png";
    PImage newIm = new File(n).exists() ? loadImage(n) : null;
    if (newIm==null){
      nullCnt++;
    } else {
      for (int nl=0;nl<nullCnt;nl++){imAL.add(null);}
      nullCnt=0;
      imAL.add(newIm);
    } 
  }
  
  ImageStack st = new ImageStack();
  st.im = new PImage[imAL.size()];
  for (int i = 0 ; i < st.im.length ; ++i){
    st.im[i] = imAL.get(i); 
  } 
    return(st);
}


// This is for some stand-alone functions on PImage data

PImage blendColourAndIntensity(PImage colorIm, PImage intensityIm){
  PImage bl = intensityIm.copy();
  PImage ci = colorIm.copy();

  int dimension = bl.width * bl.height;
  for (int i = 0; i < dimension; ++i) { 
    float intensity = brightness(bl.pixels[i])/255;
    color c = ci.pixels[i];
    bl.pixels[i] = color(intensity*red(c),intensity*green(c),intensity*blue(c));
  }
  return(bl);
}

PImage maxChannel(PImage im){
  PImage im2 = im.copy();
  int dimension = im2.width * im2.height;
  for (int i = 0; i < dimension; ++i) { 
    color c = im2.pixels[i];
    float m = max(red(c),green(c),blue(c));
    if (m*100<spec.maxChannelPercentageThreshold*255){ m=0; }
    im2.pixels[i] = color(m,m,m);
  }
  return(im2);
}

void applyIntensityTransform(PImage im, int[] map){
  im.loadPixels();
  int n = im.width * im.height;
  for (int ii=0;ii<n;ii++){
    im.pixels[ii] = color(map[round(brightness(im.pixels[ii]))]);
  }
  im.updatePixels();
}

PImage getBinaryMask(PImage im){
  if (im==null){return null;}
  PImage bi = im.copy();
  int dimension = im.width * im.height;
  for (int i = 0; i < dimension; ++i) { 
    color cc = im.pixels[i];
    if (brightness(cc) == 0){
      bi.pixels[i] = color(0);
    } else {
      bi.pixels[i] = color(255);
    }
  }
  return(bi);
}

void printImageMeans(PImage im)
{
  int redMean = 0;
  int greenMean = 0;
  int blueMean = 0;
  int satMean = 0;
  int brightMean = 0;
  int alphaMean = 0;
  int dimension = im.width * im.height;
  for (int i = 0 ; i < dimension ; ++i){
    color c = im.pixels[i];
    redMean += red(c);
    greenMean += green(c);
    blueMean += blue(c);
    satMean += saturation(c);
    brightMean += brightness(c);
    alphaMean += alpha(c);
  }
  println("red:" + redMean/dimension + "; green: " + greenMean/dimension + "; blue: " + blueMean/dimension + "; alpha: " +alphaMean/dimension 
  + "; saturation: " + satMean/dimension + "; brightness: " + brightMean/dimension );
}

void setWhite(PImage im){
  int dimension = im.width * im.height;
  for (int i = 0; i < dimension; ++i) { 
    im.pixels[i] = color(255);
  }
}

void countPixelColours(PImage im, HashMap<Integer,Integer> classCounts){
  im.loadPixels();
  for (Integer c : im.pixels){
    if (!classCounts.containsKey(c)){
      classCounts.put(c,1);
    } else {
      classCounts.put(c,1+classCounts.get(c));
    }
  }
}

  
        
