// kura_tests.ckc
// class for kuramoto oscillators
// using LISA
// author: nolan lem 
// date: 2-8-15 
// myosc class provides counter and mean-field coupling coefficient, Kn 

/// ...user control...
// '=' add oscillator from group
// '-' remove oscillator from group
// ',' decrease coupling coefficient, kn (by 0.01)
// '.' increase coupling coefficient
// '[' decrease oscillator frequency (by 0.01); 
// ']' increase oscillator frequency 
// ''' increase volume
// ';' decrease volume 
// 'p' increase envelope 
// 'o' decrease envelope 
// 'h' higher rates in tones[i] by 1.0 
// 'b' decrease rates tones[i] by 1.0  
// '8' apply LFO to output  

// how many channels?!
2 => int no_channels;

// if I want OSC input (via max)
//Std.atoi(me.arg(0)) => int my_r_port;
me.arg(0) => string myTypeTag; 
me.arg(1) => string mySample; 

<<<"starting osc cycles...">>>; 
//<<<"receiving port: ", my_r_port>>>; 
<<<"osc typetag:", myTypeTag>>>;
<<<"my sound: ", mySample>>>;  

"/msgs" => myTypeTag; 

"localhost" => string myhost; 
8888 => int my_osc_port;
8000 => int my_mag_port;

SndBuf block1;

string FILENAME1; 
//me.dir() + "woodblock_mono.wav" => string FILENAME;
if(mySample=="wb"){me.dir() + "woodblock_mono.wav" =>  FILENAME1; } 
else if(mySample=="wblow"){me.dir() + "woodblock_mono.wav" => FILENAME1;}
else if(mySample=="tabla"){me.dir() + "tabla_mono.wav" =>  FILENAME1;} 
else if(mySample=="wood"){me.dir() + "woodspin_mono.wav" =>  FILENAME1;} 
else{ me.dir() + "woodblock_mono.wav" => FILENAME1;} // default is woodblock'wb'
//me.dir() + "kalimba.wav" => string FILENAME3; 


//if( me.args() > 0 ) me.arg(0) => FILENAME2;

FILENAME1 => block1.read;

0 => block1.pos;   

// declare sampling rate for main cycle loop 
dur clk; 
0.01 => float clk_f; 
clk_f::second => clk;   

//////// how many oscillators in system? needs to == processing patch
200 => int max_oscs;
// initial number of oscillators in system
1=> int num_oscs;

float dp; // phase differential 0 -> 1  
int j; // instantiate j => 0;     

// make max number of oscs that could be used
myosc osc[max_oscs];
// oscillator array to hold period count for each osc; 
int osc_count[max_oscs]; 

// banks of oscillator/sample frequencies/rates
float tones[max_oscs];
float toneslow[max_oscs]; 
float sineBank[max_oscs];
float tablaBank[max_oscs]; 
float kn_weight[max_oscs];

3 => int no_times;  

1 => int sounds;

// for complex order params
#(0,0) => complex r;
0 => float rmag; 
0 => float rang; 

// not from processing anymore, via keystrokes 'o,p'
float env; 

if(mySample=="sine"){0.002 => env; }
else{ 0.05 => env;}
1.0 => float vol; // global volume

for(int i; i<max_oscs; i++){
    if(i<20){ ((20-i)%20) => tablaBank[i];}  
    else if(i>=20 && i<=40){ 0.5*((i+1)%20) => tablaBank[i];} 
    else if(i>40 && i<60){ 0.6*((i+1)%20) => tablaBank[i];}
    else{ Math.random2f(0.4,10.0) => tablaBank[i];}
    
    Math.random2f(0.95,1.1)*tablaBank[i] => tablaBank[i]; 
    
    12 => tablaBank[0]; 
    
    Math.random2f(6.0,20.0) => tones[i];
    Math.random2f(0.8,4.0) => toneslow[i]; 
    Math.random2(100,2000) => sineBank[i]; 
    //(i/4.0)*(i+1) => tones[i]; 
    //((i/10)%10)/5.0 => kn_weight[i];
    1.0 => kn_weight[i];     
}


//// LISA STUFF 

0.8 => float MAIN_VOLUME; 
(block1.samples()::samp/44100::samp)::second => dur GRAIN_LENGTH1;

0 => float GRAIN_POSITION;

// max allowable voices (200) 
max_oscs => int LISA_MAX_VOICES;

// sampling stuff
LiSa lisa[no_channels]; 
PoleZero blocker[no_channels]; 
Gain gain[no_channels];
NRev reverb[no_channels]; 
SinOsc lfo;
Gain lfogain[no_channels]; 
Gain lfoSineGain; 

// initialize signal chains
for(int n; n<no_channels; n++){
    load(FILENAME1) @=> lisa[n];
    blocker[n] => gain[n] => lfogain[n] => reverb[n] => dac.chan(n);
    lisa[n] => blocker[n];
    1.0 => gain[n].gain;
    0.015 => reverb[n].mix;
    0.99 => blocker[n].blockZero;
    1.0 => lfogain[n].gain; 
}
// just for control signal 
lfo => blackhole; 
0.0 => lfo.freq;
1 => lfo.gain;
1 => lfoSineGain.gain;  
0 => int LFOFLAG; // turn on and off for AM


// class for kuramoto oscillator, myosc
class myosc 
{ 
    int id; // osc id
    float uwp; // instantaneous phase
    float olduwp;
    float oscuwp; 
    float step; // controls frequency
    float kn;    
}

// key input 
KBHit kb;
//KBHit kb1;
// save complex order parameters' output to txt file 


0 => int deviceNum;

// send out via OSC --> processing 
OscOut xmit;
OscOut rmit;

OscIn oin;
OscIn oin2;

xmit.dest( myhost, my_osc_port );
rmit.dest( myhost, my_mag_port); 

0.01 => float steplow; 
0.1 => float stephigh; 




//// INITIALIZE parameters for all num_oscs (max_oscs)


for (0=> int i; i< max_oscs; i++)
{   
    // set initial phases
    Math.random2f(0, 2*pi) => osc[i].uwp; 
    // initialize old uwp
    osc[i].uwp => osc[i].olduwp;       
    i => osc[i].id;
    
    // step is freq/vel
    Math.random2f(steplow, stephigh) => osc[i].step; 
    
    0.01 => osc[i].kn; 
    
}

// initial frequencies
0.04 => osc[0].step; 
0.053 => osc[1].step; 
0.058 => osc[2].step; 
0.013 => osc[3].step; 
0.02 => osc[4].step;  

// frequency scalar
0.01*Math.random2f(100,200) => float freq_sc; 




// run the oscillator cycles
spork ~cycle();
spork ~lowFreqOsc();
// to enable keystroke input
spork ~addOsc(kb);
// spork all parameter control via MAX MSP






// keep master shred alive forever & count seconds elapsed
1 => int count; 

// master clock
while (true){
    //cherr <= count <= IO.newline(); 
    1::second => now;
    count++;     
}



//////////////////////main cycle function ////////


fun void addOsc(KBHit kb){
    while(true){ 
        kb => now; 
        while(kb.more())
        { 
            kb.getchar() => int c;
            // ';' pressed, raise volume 
            if (c == 39)
            { 
                vol + 0.05 => vol;                
                <<<"volume is now: ", vol>>>; 
            }
            // ''' pressed, lower volume
            else if (c==59){  
                vol - 0.05 => vol; 
                <<<"volume is now: ", vol>>>; 
            }
            // '=' + add oscillator 
            else if (c == 61)
            {               
                num_oscs++;
                <<<"there are now ", num_oscs , " oscillators">>>;
                // give new osc initial phase
                Math.random2f(0, 2*pi) => osc[num_oscs].uwp; 
                // initialize old uwp
                osc[num_oscs].uwp => osc[num_oscs].olduwp;       
                num_oscs => osc[num_oscs].id;
                // step is freq/vel
                Math.random2f(steplow, stephigh) => osc[num_oscs].step; 
                
            }
            // '-' - subtract oscillator
            else if (c == 45){
                num_oscs--; 
                <<<"there are now ", num_oscs , " oscillators">>>;                
            }
            // '0' super increase num_oscs
            else if(c== 48 ){ 
                num_oscs + 10 => num_oscs;
                <<<"there are now ", num_oscs , " oscillators">>>;                
            }
            // '0' super decrease num_oscs
            else if(c== 57 ){ 
                num_oscs - 10 => num_oscs;
                <<<"there are now ", num_oscs , " oscillators">>>;                
            }
            else if (c == 46){ 
                for (int i; i< num_oscs; i++){ 
                    osc[i].kn + steplow => osc[i].kn;                     
                    <<<"osc[",i,"] kn is:", osc[i].kn>>>; 
                    
                }
                //<<<"kn is:", osc[0].kn>>>; 
                
            }
            else if (c == 44){ 
                for (int i; i<num_oscs; i++){ 
                    osc[i].kn - steplow => osc[i].kn;   
                    <<<"osc[",i,"] kn is:", osc[i].kn>>>; 
                    
                }
                //<<<"kn is: ", osc[0].kn>>>; 
            }
            // '[' decrease fundamental freq
            else if (c == 91){ 
                for (int i; i<num_oscs; i++){ 
                    osc[i].step - 0.005 => osc[i].step;   
                } 
                <<<"freq step (of osc[0]) is:", osc[0].step>>>; 
                
            }
            // ']' increase fundamental freq            
            else if (c == 93){ 
                for (int i; i<num_oscs; i++){ 
                    osc[i].step + 0.005 => osc[i].step;   
                } 
                <<<"freq step (of osc[0]) is:", osc[0].step>>>; 
            }
            
            // '[' decrease fundamental freq
            else if (c == 102){ 
                for (int i; i<num_oscs; i++){ 
                    osc[i].step - 0.1 => osc[i].step;   
                } 
                <<<"freq step (of osc[0]) is:", osc[0].step>>>; 
                
            }
            // ']' super increase fundamental freq            
            else if (c == 114){ 
                for (int i; i<num_oscs; i++){ 
                    osc[i].step + 0.1 => osc[i].step;   
                } 
                <<<"freq step (of osc[0]) is:", osc[0].step>>>; 
            }            
            // '1' changes sound boolean
            else if (c == 49){ 
                //tones[i]*1.3 => tones[i];
                !sounds => sounds; 
                <<<"sounds:",sounds>>>;   
                
            }
            // '2' fades out volume
            else if (c ==50){ 
                <<<"sporking fadeOut">>>; 
                spork ~fadeOut(); 
                
            }
            // 'o' decreases envelope
            else if(c == 111){ 
                env - 0.001 => env; 
                <<<"decreases envelope time:", env>>>;                 
            }
            // 'p' increases envelope
            else if(c == 112){ 
                env + 0.001 => env; 
                <<<"increases envelope time:", env>>>;                 
            }
            // 'b' lowers rates in tones[i] array by 1.0 used by wb 
            else if(c==98){ 
                for (int i; i<num_oscs; i++){ 
                    tones[i]- 1.0 => tones[i];
                    sineBank[i] - 10.0 => sineBank[i];    
                }
                <<<"tones[0] being lowered to:", tones[0]>>>; 
                <<<"sineBank[0] being lowered to:", sineBank[0]>>>; 
                
            }
            // 'h' to higher rates in tones[i] array used by wb    
            else if(c==72){ 
                for (int i; i<num_oscs; i++){ 
                    tones[i]+ 1.0 => tones[i];   
                    sineBank[i] + 10.0 => sineBank[i]; 
                }
                <<<"tones[0] being increased to:", tones[0]>>>; 
                <<<"sineBank[0] being increased to:", sineBank[0]>>>;     
            }
            else if(c==56){ 
                !LFOFLAG => LFOFLAG;                 
            }                
            //}            
            cherr <= IO.newline();             
        }
        // keystroke clock period here
        0.2::second => now; 
    }
} 


fun void lowFreqOsc(){ 
    while(true){
        if(LFOFLAG==1){
            
            0.13 => lfo.freq;
        }
        else if(LFOFLAG==0){
            0.0 => lfo.freq;
            
        }  
        for(int n; n<no_channels; n++){
            (lfo.last()*0.25 + 0.5) => lfogain[n].gain;
            (lfo.last()*0.25 + 0.5) => lfoSineGain.gain;                
        }
        10::ms => now;
    }
}



fun void cycle()
{         
    
    <<<"---------starting cycle-----------">>>;      
    while(true){      
        
        // start osc messages
        xmit.start(myTypeTag);
        rmit.start(myTypeTag + "rmag");       
        
        // for all oscs up to num_oscs, move phases forward and store phases in p[]
        for(0 => int i; i< num_oscs; i++)     
        { 
            
            // XOR logic to check for zero crossings (old uwp and uwp have diff signs)           
            if( (osc[i].olduwp> 0)^(osc[i].uwp > 0) ==1){ 
                //<<<"backwards">>>; 
                if(mySample == "sine"){                   
                    spork ~soundevent(osc[i].id, osc_count[i], no_times);                   
                }
                else{ 
                    spork ~fireGrain(osc[i].id, GRAIN_LENGTH1, lisa[i%no_channels], osc_count[i], no_times);                   
                }
                if(osc_count[i]<no_times){ osc_count[i]++;}
                else{0 => osc_count[i];}     
                
            } 
            
            // update old uwp to detect zero crossings 
            osc[i].uwp => osc[i].olduwp;   
            
            if ( osc[i].uwp >= (2*pi) || osc[i].uwp <= (-2*pi))
            {
                if(i%num_oscs == i){ 
                    if(osc_count[i]<no_times){ 
                        //<<<osc_count[i]>>>; 
                        osc_count[i]++;  
                    }
                    else{
                        0 => osc_count[i];
                    }                    
                    
                    if(mySample == "sine"){                   
                        spork ~soundevent(osc[i].id, osc_count[i], no_times);                   
                        
                    }
                    else{ 
                        spork ~fireGrain(osc[i].id, GRAIN_LENGTH1, lisa[i%no_channels], osc_count[i], no_times);                   
                    }   
                    
                }                 
                // reset phase
                //osc[i].uwp => float tempuwp; 
                0 => osc[i].uwp;   
                //osc[i].uwp%6.2918=> osc[i].uwp;
                
            }
            
            // send phase angle thru OSC
            osc[i].uwp => xmit.add;
            
            r + (Math.cos(osc[i].uwp) + Math.i*Math.sin(osc[i].uwp)) => r; 
            
        }
        
        // get magnitude of phase coherence, (mean radius), normalize        
        r/num_oscs => r; 
        Math.sqrt(Math.pow(r.re,2) + Math.pow(r.im,2)) => rmag;
        
        Math.atan(r.im/r.re) => rang;
        
        
        // account for angle orientation 
        if (r.re < 0 && r.im >0){ 
            rang + pi => rang; 
        }
        if (r.re <0 && r.im < 0){ 
            rang + pi => rang;  
        }
        if( r.re >0 && r.im <0){
            rang + 2*pi => rang;  
        } 
        
        // apply group phase differential to oscs' phases
        for (int i; i<num_oscs; i++){ 
            
            osc[i].kn*kn_weight[i]*Math.sin(rang - osc[i].uwp) => dp;
            // <<<"osc ", i, " is: ", dp>>>; 
            osc[i].uwp + osc[i].step + dp => osc[i].uwp; 
        }
        
        // send array of oscs' positions to processing
        xmit.send();
        rmag => rmit.add;
        rang => rmit.add;
        rmit.send();        
        
        // reset complex order params
        #(0,0) => r; 
        0 => rang; 
        0 => rmag;       
        
        clk => now; 
    }
}


//////////// 

fun void fireGrain(int id, dur graindur, LiSa lisa, int osc_count, int no_times){
    
    GRAIN_POSITION => float pos;
    float rate; 
    if(mySample == "tabla"){
        if(osc_count==0){
            1.33*tablaBank[id] => rate;
        }
        else{tablaBank[id] => rate;}
    } 
    else if(mySample == "wb"){ tones[id] =>  rate;}
    else if(mySample =="wblow"){ toneslow[id] => rate;}
    else{ tones[id] => rate;}
    //tones[id] => float rate;
    
    ((graindur/second)/rate)::second => dur grainLen; 
    (env*grainLen/second)::second => dur rampTime; 
    
    
    if( lisa != null){ 
        
        spork ~grain(id, lisa, pos::second, grainLen, rampTime, rampTime, rate, osc_count, no_times );       
    } 
    
    grainLen => now;     
}

fun void grain(int id, LiSa lisa, dur pos, dur grainLen, dur rampUp, dur rampDown, float rate, int osc_count, int no_times){ 
    
    // get a voice to use
    lisa.getVoice() => int voice;
    /*
    <<<"pos:", pos>>>; 
    <<<"grainLen:", grainLen/second>>>; 
    <<<"rampUp:", rampUp/second>>>; 
    <<<"rampDown", rampDown/second>>>; 
    <<<"rate:",rate>>>;
    <<<"voice:", voice>>>; 
    */
    // if available
    if( voice > -1 )
    {
        // set rate
        //spork ~getChan(id); 
        lisa.rate(voice,rate);
        lisa.voiceGain(voice, vol+Math.random2f(-0.1,0.1));
        // set playhead
        lisa.playPos( voice, pos );
        // alternate channels (for stereo) for each osc
        //panner.pan((-1.0+(id%2)*2)/2.0);
        
        
        // ramp up
        lisa.rampUp( voice, rampUp );
        // wait
        (grainLen - rampUp) => now;
        // ramp down
        lisa.rampDown( voice, rampDown );
        // wait
        rampDown => now;
    }
    
}

/*
fun void getChan(int id){ 
    <<<"turning ON chan ", (id%no_channels)>>>; 
    1 => g[(id%no_channels)].gain; 
    for(int n; n<no_channels; n++){ 
        if((id%no_channels) != n){ 
            <<<"turning of chan ", n>>>; 
            0 => g[n].gain;   
        }
        
    }
    
}
*/


fun void soundevent(int id, float osc_count, int no_times){ 
    
    SinOsc s => Envelope e=> dac.chan(id%no_channels); 
    //<<<vol/num_oscs>>>; 
    vol/3 => s.gain;
    //0.5 => s.gain; 
    //0.3 => dac.gain; 
    /*
    if(osc_count == no_times){250*(freq_sc + (id+1)) => s.freq;} 
    else{
        200*(freq_sc + (id+1)) => s.freq; 
    }
    */
    if(osc_count == no_times){sineBank[id]*Math.random2f(1.1,1.33) => s.freq;} 
    else{
        sineBank[id] => s.freq; 
    }    
    //(1/((num_oscs)*10.0))::second => dur notelen;
    
    (env + Math.random2f(0.001,0.001))::second => dur notelen;
    
    1 => e.target;
    notelen => e.duration;     
    1 => e.keyOn; 
    notelen + notelen => now; 
    1 => e.keyOff; 
    notelen =>now;
    
}

//utility function 
// get max in array
fun float getMax(float arr[]){ 
    
    arr[0] => float tempmax; 
    for(1 => int i; i<arr.cap(); i++){ 
        if((arr[i] > arr[i-1]) && (arr[i] > tempmax)){ 
            arr[i] => tempmax;
        }
    }
    //<<<"largest num in array:", tempmax>>>; 
    return tempmax;    
}

fun float getMin(float arr[]){ 
    
    arr[0] => float tempmin; 
    for(1 => int i; i<arr.cap(); i++){ 
        if((arr[i] < arr[i-1]) && (arr[i] < tempmin)){ 
            arr[i] => tempmin;
        }
    }
    //<<<"smallest num in array:", tempmin>>>; 
    return tempmin;    
}



fun void fadeOut(){ 
    1.0 => float fader;
    for(int n; n<100; n++){ 
        fader - 0.01 => fader;
        <<<fader>>>;  
        fader => dac.gain;
        100::ms => now; 
    }
    <<<"thanks for playing me!">>>; 
    me.exit();
    
}

// load file into a LiSa
fun LiSa load( string filename)
{
    // sound buffer
    SndBuf buffy;
    // load it
    filename => buffy.read;
    
    // new LiSa
    LiSa lisa;
    // set duration
    buffy.samples()::samp => lisa.duration;
    
    // transfer values from SndBuf to LiSa
    for( 0 => int i; i < buffy.samples(); i++ )
    {
        // args are sample value and sample index
        // (dur must be integral in samples)
        lisa.valueAt( buffy.valueAt(i), i::samp );        
    }
    
    // set LiSa parameters
    lisa.play( false );
    lisa.loop( false );
    lisa.maxVoices( LISA_MAX_VOICES );
    
    return lisa;
}

















