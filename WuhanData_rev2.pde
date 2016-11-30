
/** 
 * Serial Call-Response 
 * by Tom Igoe. 
 * 
 * Sends a byte out the serial port, and reads 3 bytes in. 
 * Sets foregound color, xpos, and ypos of a circle onstage
 * using the values returned from the serial port. 
 * Thanks to Daniel Shiffman  and Greg Shakar for the improvements.
 * 
 * Note: This sketch assumes that the device on the other end of the serial
 * port is going to send a single byte of value 65 (ASCII A) on startup.
 * The sketch waits for that byte, then sends an ASCII A whenever
 * it wants more data. 
 */
 

import processing.serial.*;
import java.io.BufferedWriter;
import java.io.FileWriter;
 

int bgcolor;			     // Background color
int fgcolor;			     // Fill color
Serial myPort;                       // The serial port
short[] serialInArray = new short[30];    // Where we'll put what we receive
//int headerCount = 0;                 //counter for displaying the header after so many lines  
int serialCount = 0;                 // A count of how many bytes we receive
boolean firstContact = false;        // Whether we've heard from the microcontroller
int last_call = millis();
float CO2,CH4,CO,H2,O2,CmHn,Energy;
color CO2col = #FF0000;
color CH4col = #00FF00;
color COcol = #0000FF;
color H2col = #FF00FF;
color O2col = #00FFFF;
color CmHncol = #FFFF00;
String filename;
int graphPosition = 0;
int lim = 65000;  //reading will show ~65543 when value is negative (suspected), used to filter out this erroneous reading. 

//energy values are in MJ/kg 
float heatvalue_h2 = 121.0;
float heatvalue_co = 10.2;
float heatvalue_me = 50.2;
float heatvalue_ch = 46.0;

// in kg/m3
float density_h2 = 0.0899;
float density_co = 1.250;
float density_me = 0.717;
float density_ch = 1.882;

float Ratio;

void setup() {
  
  size(1024, 256);  // Stage size
  noStroke();      // No border on the next thing drawn

  // Print a list of the serial ports, for debugging purposes:
  printArray(Serial.list());

  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  // Write a header line for the file
  filename = "Wuhan Gas Data "+year()+"-"+nf(month(),2)+"-"+nf(day(),2)+" "+nf(hour(),2)+"h"+nf(minute(),2)+"m"+nf(second(),2)+"s";
  saveSensorData(true);
  background(bgcolor);
}

void draw() {
  if (millis()-last_call>1000) {
    requestSensorData();
    //Move image over by 1 pixel
    //loadPixels();
    //arrayCopy(pixels, 0, pixels, width, (height - 1) * width);
    //for (int r = 0; r < height; r++) {
    //  arrayCopy(pixels, width * r, pixels, width * r + 1, width-1);
    //}
    //arrayCopy(pixels, 0, pixels, width, (height - 1) * width);
    //updatePixels();
      //background(bgcolor);
    fill(bgcolor);
    stroke(bgcolor);
    rect(0,0,128,height);
    fill(255);
    fill(COcol);
    text("CO:"+CO,5,20);
    fill(CO2col);
    text("CO2:"+CO2,5,40);
    fill(CH4col);
    text("CH4:"+CH4,5,60);
    fill(CmHncol);
    text("CmHn:"+CmHn,5,80);
    fill(H2col);
    text("H2:"+H2,5,100);
    fill(O2col);
    text("O2:"+O2,5,120);
    fill(255,255,255);
    text("Energy:"+Energy,5,140);
    stroke(128);
    line(128,0,128,height);
    //Draw points based on gas levels
    if (graphPosition > width) {
      graphPosition = 128;
    }
    if (graphPosition < 128) {
      graphPosition = 128;
    }
    //clear prevision lines
    stroke(bgcolor);
    line(graphPosition,0,graphPosition,height);
    stroke(#CCCCCC);
    line(graphPosition+1,0,graphPosition+1,height);
    //Draw gases...
    stroke(COcol);
    fill(COcol);
    point(graphPosition,height-CO*height/25);
    stroke(CO2col);
    point(graphPosition,height-CO2*height/25);
    stroke(CH4col);
    point(graphPosition,height-CH4*height/25);
    stroke(CmHncol);
    point(graphPosition,height-CmHn*height/25);
    stroke(H2col);
    point(graphPosition,height-H2*height/25);
    stroke(O2col);
    point(graphPosition,height-O2*height/25);
    graphPosition++;
    last_call = millis();
  }
}

void serialEvent(Serial myPort) {
  
  // read a byte from the serial port:
  short inByte = (short) myPort.read();
  // if this is the first byte received, and it's an A,
  // clear the serial buffer and note that you've
  // had first contact from the microcontroller. 
  // Otherwise, add the incoming byte to the array:
  if (firstContact == false) {
    if (inByte == 0x16 || inByte == 0x06) { 
      if (inByte == 0x16) {
        //println("Success");
        println("H2,CO,CO2,CH4,CmHn,O2,Energy(MJ/m3)");
      }
      if (inByte == 0x06) {
        println("Fail");
      }
      myPort.clear();          // clear the serial port buffer
      firstContact = true;     // you've had first contact from the microcontroller
      
    } 
  } 
  else {
    
    // Add the latest byte from the serial port to array:
    serialInArray[serialCount] = inByte;
    serialCount++;

    if (serialCount > 19 ) {
    
      int a = 4; //offset
      int val; 
      
      val = (short) serialInArray[a+7]| serialInArray[a+6]<<8;
      if (val>lim){
        val = 0;        
      }
      H2 = val/100.0;
      print(H2+","); 
      
      
      val = (short) serialInArray[a+13]| serialInArray[a+12]<<8;
      if (val>lim){
        val = 0;        
      }
      CO = val/100.0;
      print(CO+",");
      
      
      val = (short) serialInArray[a+1]|serialInArray[a+0]<<8;
      if (val>lim){
        val = 0;        
      }
      O2 = val/100.0;
      CO2 = val/100.0;
      print(CO2+",");
      
      
      val = (short) serialInArray[a+3]| serialInArray[a+2]<<8;
      if (val>lim){
        val = 0;        
      }
      CH4 = val/100.0;
      print(CH4+",");   
      
      
      val = (short) serialInArray[a+5]| serialInArray[a+4]<<8;
      if (val>lim){
        val = 0;        
      }
      CmHn = val/100.0; 
      print(CmHn+","); 
      
      
      val = (short) serialInArray[a+9]| serialInArray[a+8]<<8;
      if (val>lim){
        val = 0;        
      }
      O2 = val/100.0;
      print(O2+","); 
      
      
      val = (short) serialInArray[a+11]| serialInArray[a+10]<<8;
      Energy = val;
      Energy = (H2 * heatvalue_h2 * density_h2) + (CO * heatvalue_co * density_co) + (CH4 * heatvalue_me * density_me) + (CmHn * heatvalue_ch * density_ch);
      String Energy_str = nf(Energy,0,2);
      
      print(Energy_str);
      print(",");
  
      Ratio = H2/CO;
      print(Ratio);
      
      
      
      
      println();
      // Save the data to file
      saveSensorData(false);
      // Reset serialCount:
      serialCount = 0;
      
    }
  }
}

void requestSensorData() {
      myPort.write(0x11);
      myPort.write(0x01);
      myPort.write(0x01);
      myPort.write(0xED);
}

void saveSensorData(boolean header) { //Code adapted from http://forum.processing.org/two/discussion/561/easiest-way-to-append-to-a-file-in-processing
  BufferedWriter output = null;
  try {
    output = new BufferedWriter(new FileWriter(filename, true)); //the true will append the new data
    if (header) {
      output.write("Time,H2,CO,CO2,CH4,CmHn,O2,Energy(MJ/m3),Ratio\n");
    } else {
      output.write(year()+"-"+month()+"-"+day()+" "+hour()+":"+minute()+":"+second()+","+H2+","+CO+","+CO2+","+CH4+","+CmHn+","+O2+","+Energy+","+Ratio+"\n");
    }
  }
  catch (IOException e) {
    println("Writing to File Failed:");
    e.printStackTrace();
  }
  finally {
    if (output != null) {
      try {
        output.close();
      } catch (IOException e) {
        println("Error while closing the writer");
      }
    }
  }
  //exit();
}