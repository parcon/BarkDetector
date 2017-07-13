import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

import processing.video.*;

import twitter4j.conf.*;
import twitter4j.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import java.util.*;


PrintWriter output;

Minim minim;
AudioInput in;
Capture cam;

//CHANGE THESE
float  threshold = 1.5;
int waitTime = 4500;
boolean sounds =0;
//

float sum,avg,currHigh;

AudioPlayer[] audioFiles = new AudioPlayer[3];
int currAudio = 0;
int audioCount = 3;
boolean audioPlaying = false;
int hour = 0; //hour var to be adjusted to 12 hour time
int photocount=0;

boolean barkDetected = false;
int barkCounter = 0;
long barkTime;

PFont font;

Twitter twitter;

// runs only once
void setup()
{
  size(256, 200, P3D);

  minim = new Minim(this);
  // minim.debugOn();

  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO, 256);//

  // audio files
  // adjust files as needed
  audioFiles[0] = minim.loadFile("1.mp3", 2048);
  audioFiles[1] = minim.loadFile("2.mp3", 2048);
  audioFiles[2] = minim.loadFile("3.mp3", 2048);

  font = loadFont("HelveticaNeue-Bold-100.vlw");
  
  output = createWriter("barklog"+year()+"-"+month()+"-"+day()+"-"+hour()+"-"+minute()+".txt"); 

  //Camera things
  //size(1080, 720);

  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();     
  }
  
  //twitter things
  
    ConfigurationBuilder cb = new ConfigurationBuilder();
    cb.setOAuthConsumerKey("*");
    cb.setOAuthConsumerSecret("*");
    cb.setOAuthAccessToken("*");
    cb.setOAuthAccessTokenSecret("*");

    TwitterFactory tf = new TwitterFactory(cb.build());

    twitter = tf.getInstance();
    
    tweet("Bark "+barkCounter);
}


// runs continuously
void draw()
{
  if (barkDetected && audioFiles[currAudio].isPlaying() ) {
    background(0,100,0);
  }  
  else if (barkDetected && !audioFiles[currAudio].isPlaying() ) {
    background(200,100,50);
  } 
  else {
    background(100,0,0);
  }
  
  stroke(255);
  
  // audio detection stuff
  
  sum = 0.0;
  for(int i = 0; i < in.bufferSize() - 1; i++)
  {
    sum += in.left.get(i)*100 +  in.right.get(i)*100;
    line(i, 50 + in.left.get(i)*50, i+1, 50 + in.left.get(i+1)*50);
    line(i, 150 + in.right.get(i)*50, i+1, 150 + in.right.get(i+1)*50);
  }

  currHigh = sum/in.bufferSize();
  
  
  if (currHigh > threshold && !audioFiles[currAudio].isPlaying() && (millis() - barkTime > 1000)) {
    //set / reset barkTime
    barkDetected = true;
    barkTime = millis();

    barkCounter++;
    
    tweet("Bark,"+barkCounter+","+currHigh);
    
    hour = hour();
    //if (hour >12){ hour = hour -12;} //adjust hour to 12 hour time
    
    //take image
    if (cam.available() == true) {
    cam.read();
    photocount++;
    PImage pg = cam.get();
    pg.save("image"+photocount+".png");
    }
    
    
    println("bark detected: " + barkCounter + " time: "+ hour + ":" + minute()+ " second "+ second());
     output.println("\"bark\",\""+barkCounter+"\",\""+currHigh+"\",\""+hour + ":" + minute()+ ":"+ second()+"\""); // Write the coordinate to the file
    
  } 
  else if (barkDetected && !audioPlaying && !audioFiles[currAudio].isPlaying() && (millis() - barkTime > waitTime) ) {
    //start audio if bark was detected a few seconds ago
    audioPlaying = true;
    audioFiles[currAudio].rewind();
    audioFiles[currAudio].play();
    
    hour = hour();
    //if (hour >12){ hour = hour -12;} //adjust hour to 12 hour time
    println("playing audio file: " + currAudio + " time: "+ hour + ":" + minute()+ " second "+ second() );
    output.println("\"audio\",\""+hour + ":" + minute()+ ":"+ second()+"\""); // Write the coordinate to the file
  } 
  else if (barkDetected && audioPlaying && !audioFiles[currAudio].isPlaying()  ) {
    //audio file is done playing, reset things and increment to next audio file
    resetAudio();
    println("ending audio \nq");
    //increment audiotrack counter
    if (currAudio < audioCount-1) {
      currAudio += 1;
    } 
    else {
      currAudio = 0;
    }
  }

  //display bark count
  textFont(font); 
  textAlign(CENTER);
  int fWidth = (int)textWidth(Integer.toString(barkCounter));
  text(barkCounter,(width/2), (height/2)+35);
  
  output.flush();
}

void resetAudio() {
  barkDetected = false;
  audioPlaying = false;
  audioFiles[currAudio].loop(1);
  audioFiles[currAudio].pause();
}
void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  for(int i = 0; i<audioCount; i++) {
    audioFiles[i].close();
  }
  minim.stop();

  super.stop();
}

void tweet(String words)
{
    try
    {
        Status status = twitter.updateStatus(words);
        System.out.println("Status updated to [" + status.getText() + "].");
    }
    catch (TwitterException te)
    {
        System.out.println("Error: "+ te.getMessage());
    }
}
