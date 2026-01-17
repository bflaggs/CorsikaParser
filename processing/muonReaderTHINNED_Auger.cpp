// To compile:
// OLD METHOD
// g++ -O0 -fbounds-check muonReaderTHINNED.cpp -o muonReader -std=c++11 -lm
// NEW METHOD
// Run command "make" in directory where this file exists (also make sure its Makefile exits in the same directory)

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <algorithm>
#include <math.h>
#include <bitset>
#include <climits>
using namespace std;
#include <glob.h>

#define PI 3.14159265

// Used for defining the type of corsika simulation
enum class SimType {Thinned, Standard};

bool getBinary(float g, bool thinned) {
  union
  {
    float input; // assumes sizeof(float) == sizeof(int)
    int   output;
  } data1;
  union
  {
    float input; // assumes sizeof(float) == sizeof(int)
    int   output;
  } data1a;
  union
  {
    float input; // assumes sizeof(float) == sizeof(int)
    int   output;
  } data2;

  if (thinned) {
    data1.input = 3.67252e-41; // must be this for thinned files
  } else {
    data1.input = 3.21346e-41; // must be this for non-thinned (standard) files
  }

  data1a.input = 4.59037e-41;
  data2.input = g;

  std::bitset<sizeof(float) * CHAR_BIT> bits1(data1.output);
  std::bitset<sizeof(float) * CHAR_BIT> bits1a(data1a.output);
  std::bitset<sizeof(float) * CHAR_BIT> bits2(data2.output);
  if ((bits1 == bits2) || (bits1a == bits2)) {
    return true;
  }

  return false;
}

/// --------------------------------------------------------------------------------------------
/// MAIN PART - READING.....
/// --------------------------------------------------------------------------------------------


int main (int argc, char *argv[]) {

  if (argc < 3) {
    cerr << "--------------------------------------------------------------------------------\n";
    cerr << "This program counts the muons and e+/- in the air shower at different distances:\n";
    cerr << "You must give the input filename and type of CORSIKA file (thinned or standard)\n";
    cerr << "Usage is ./muonReader <InputFile1> [InputFile2 InputFile3 ...] --FILE_FLAG\n";
    cerr << "--FILE_FLAG can be: --thinned or --standard\n";
    cerr << "--------------------------------------------------------------------------------\n";

    return 0;
  }

  std::string filePath = argv[1];
  std::string fileFlag = argv[argc - 1];

  SimType mode;

  if (fileFlag == "--thinned") {
    mode = SimType::Thinned;   // thinned corsika file
  } else if (fileFlag == "--standard") {
    mode = SimType::Standard;   // standard corsika file
  } else {
    cerr << "--------------------------------------------------------------------------\n";
    cerr << "Invalid file flag given!\n";
    cerr << "Usage is ./muonReader <InputFile1> [InputFile2 InputFile3 ...] --FILE_FLAG\n";
    cerr << "--FILE_FLAG must be either: --thinned or --standard\n";
    cerr << "--------------------------------------------------------------------------\n";
    return 0;
  }

  // Ternary operations
  // If mode is Thinned, then use "thinned corsika" record size, else use "standard corsika" record size
  const int nrecstd = (mode == SimType::Thinned) ? 26216 : 22940;
  const int nsblstd = (mode == SimType::Thinned) ? 312 : 273;

  // Other constants
  const int numbstd = nrecstd / 4;     // = 6554 for "thinned corsika", = 5735 for "standard corsika"
  float sdata[numbstd];                // to read data for a single corsika record

  // Constant for ternary operation to define particle weights in data block
  const bool isThin = (mode == SimType::Thinned) ? true : false;

  vector<string> possible_headers = {"RUNH", "EVTH", "LONG", "EVTE", "RUNE"};

  glob_t glob_result;
  glob(filePath.c_str(), GLOB_TILDE, NULL, &glob_result);

  /// init variables
  bool BROKENflag = false;
  int EVTEcnt = 0;
  int nrShow = 0;
  float primaryID, primaryEnergy; 
  double zenith, azimuth, azimuthCorr;
  int numObsLevels, CurvedObsLevFlag;
  double obslev;
  primaryID = 0.;
  primaryEnergy = 0.;
  zenith = 0.;
  azimuth = 0.;
  azimuthCorr = 0.;
  CurvedObsLevFlag = 0;

  /// --------------------------------------------------------------------------------------------
  /// THE MAIN LOOP
  /// --------------------------------------------------------------------------------------------
  /// This reads all input files one by one
  for (unsigned int k = 1; k < argc - 1; ++k) {
    EVTEcnt = 0;
    BROKENflag = false;

    std::string file_ = argv[k];

    if (!(file_.find(".long") != std::string::npos)) {

      ifstream is (file_, ifstream::binary);
      // cerr << "fileName -> " << file_ << endl;

      float nMuons = 0.;
      float nMuons1 = 0.;
      float nMuons500 = 0.;
      float nMuons1000 = 0.;

      int muonThin1 = 0;
      float thinWeight1 = 0.;

      int muonThin500 = 0;
      float thinWeight500 = 0.;

      float nMuDist50 = 0.;
      float nMuDist100 = 0.;
      float nMuDist150 = 0.;
      float nMuDist200 = 0.;
      float nMuDist250 = 0.;
      float nMuDist300 = 0.;
      float nMuDist350 = 0.;
      float nMuDist400 = 0.;
      float nMuDist450 = 0.;
      float nMuDist500 = 0.;
      float nMuDist550 = 0.;
      float nMuDist600 = 0.;
      float nMuDist650 = 0.;
      float nMuDist700 = 0.;
      float nMuDist750 = 0.;
      float nMuDist800 = 0.;
      float nMuDist850 = 0.;
      float nMuDist900 = 0.;
      float nMuDist950 = 0.;
      float nMuDist1000 = 0.;

      float nEM = 0;

      float nEMDist50 = 0.;
      float nEMDist100 = 0.;
      float nEMDist150 = 0.;
      float nEMDist200 = 0.;
      float nEMDist250 = 0.;
      float nEMDist300 = 0.;
      float nEMDist350 = 0.;
      float nEMDist400 = 0.;
      float nEMDist450 = 0.;
      float nEMDist500 = 0.;
      float nEMDist550 = 0.;
      float nEMDist600 = 0.;
      float nEMDist650 = 0.;
      float nEMDist700 = 0.;
      float nEMDist750 = 0.;
      float nEMDist800 = 0.;
      float nEMDist850 = 0.;
      float nEMDist900 = 0.;
      float nEMDist950 = 0.;
      float nEMDist1000 = 0.;

      /// Read block = record --------------------------------------------------------
      while ( is.read((char*)&sdata, sizeof(sdata)) ) { /// get full block of data at once
        if ( !getBinary( sdata[0], isThin ) ) { /// skip the first  record length sdata[0]
          cerr << "This file is corrupted, this is not a record length - beginning of block!" << endl;
          BROKENflag = true;
          break;
        }
        /// iterate over 21 sub block inside this block
        for (int j = 0; j < 21; j++) {
          string head_word = (string) (char *) &sdata[j * nsblstd + 1];
          head_word = head_word.substr (0, 4); /// dirty hack!
          if ( find( possible_headers.begin(), possible_headers.end(), head_word ) != possible_headers.end() ) {
            if (head_word == "RUNH") {
              nrShow = sdata[j * nsblstd + 93];
            } else if (head_word == "EVTH") {
              ///  Reading primary type and energy
              primaryID = sdata[j * nsblstd + 1 + 2];
              primaryEnergy = sdata[j * nsblstd + 1 + 3];
              zenith = sdata[j * nsblstd + 11];
              azimuth = sdata[j * nsblstd + 12];
              azimuthCorr = azimuth - PI;
              numObsLevels = sdata[j * nsblstd + 47]; // Number of observation levels
              obslev = sdata[j * nsblstd + 47 + 1]; // Height of first observation level in cm (will only be 1 obslev if curved surface)
              CurvedObsLevFlag = sdata[j * nsblstd + 168]; // == 1 if observation level is curved, == 0 if flat
              cout << primaryID << " " << primaryEnergy << ' ' << zenith << ' ' << azimuth << ' ';
            } else if (head_word == "EVTE") {
              EVTEcnt += 1;
            }
          }
          else { /// READ DATA -> iterate every 7th position
            for (int i = j * nsblstd + 1; i <= (j * nsblstd + nsblstd); i += 8 ) {
              float particle_id = sdata[i];
              int idpa =  (int)particle_id / 1000;
              /// ensure you grab only MUONS
              if ( idpa == 5 || idpa == 6 ) {
                float px = sdata[i + 1];
                float py = sdata[i + 2];
                float pz = sdata[i + 3];
                float x  = sdata[i+4];
                float y  = sdata[i+5];
                // float t  = sdata[i+6];

                // Set weights from data block for thinned showers, else set weights to 1.0 for standard showers
                float w = isThin ? sdata[i+7] : 1.0;

                // Some variables for each muon that might be useful in the future...
                //~ double pz_norm = -pz/sqrt( pz*pz + py*py + px*px );
                //~ double theta   = acos( pz_norm); // in degress
                //~ double zenith  = acos(-pz_norm); // in rad

                double massMu = 0.105658357;

                /// Kinetic energy  !!!
                double ekinMu = sqrt ( px * px + py * py + pz * pz + massMu * massMu) - (massMu) ;

                double dist;

                // Distance to shower axis converted to meters, shower axis coords. are defined as (0, 0, 0)
                if ( CurvedObsLevFlag == 1 ) {
                  // If observation level is curved then account for curvature of Earth's surface in distance calculation
                  // Need to define necessary variables first
                  double radEarthPlusObslev = 637131500. + obslev;

                  double theta = sqrt ( x*x + y*y ) / radEarthPlusObslev;
                  double phi = atan2 (y, x);

                  double D = radEarthPlusObslev * sin(theta);

                  double xCart = D * cos(phi);
                  double yCart = D * sin(phi);
                  double zCart = radEarthPlusObslev * cos(theta) - 637131500.;

                  dist = sqrt ( (xCart - 0.)*(xCart - 0.) + (yCart - 0.)*(yCart - 0.)
                         + (zCart - obslev)*(zCart - obslev) ) / 100. ;           
                } else {
                  // If observation level is not curved then just calculate distance for a flat surface
                  dist = sqrt ( x*x + y*y - x*x*sin(zenith)*sin(zenith)*cos(azimuth)*cos(azimuth)
                         - y*y*sin(zenith)*sin(zenith)*sin(azimuth)*sin(azimuth)
                         - 2*x*y*sin(zenith)*sin(zenith)*cos(azimuth)*sin(azimuth) ) / 100. ;
                }

                nMuons += w;

                if ( ekinMu > 1. ) {
                  nMuons1 += w;

                  // For testing thinning effects
                  if ( w > 1. ) {
                    muonThin1 += 1;
                    thinWeight1 += w;
                  }
                }

                if ( ekinMu > 500. ) {
                  nMuons500 += w;

                  // For testing thinning effects
                  if (w > 1. ) {
                    muonThin500 += 1;
                    thinWeight500 += w;
                  }
                }

                if ( ekinMu > 1000. ) {
                  nMuons1000 += w;
                }

                if ( dist <= 50. ) {
                  nMuDist50 += w;
                }

                if ( dist <= 100. ) {
                  nMuDist100 += w;
                }

                if ( dist <= 150. ) {
                  nMuDist150 += w;
                }

                if ( dist <= 200. ) {
                  nMuDist200 += w;
                }

                if ( dist <= 250. ) {
                  nMuDist250 += w;
                }

                if ( dist <= 300. ) {
                  nMuDist300 += w;
                }

                if ( dist <= 350. ) {
                  nMuDist350 += w;
                }

                if ( dist <= 400. ) {
                  nMuDist400 += w;
                }

                if ( dist <= 450. ) {
                  nMuDist450 += w;
                }

                if ( dist <= 500. ) {
                  nMuDist500 += w;
                }

                if ( dist <= 550. ) {
                  nMuDist550 += w;
                }

                if ( dist <= 600. ) {
                  nMuDist600 += w;
                }

                if ( dist <= 650. ) {
                  nMuDist650 += w;
                }

                if ( dist <= 700. ) {
                  nMuDist700 += w;
                }

                if ( dist <= 750. ) {
                  nMuDist750 += w;
                }

                if ( dist <= 800. ) {
                  nMuDist800 += w;
                }

                if ( dist <= 850. ) {
                  nMuDist850 += w;
                }

                if ( dist <= 900. ) {
                  nMuDist900 += w;
                }

                if ( dist <= 950. ) {
                  nMuDist950 += w;
                }

                if ( dist <= 1000. ) {
                  nMuDist1000 += w;
                }

              // Now do case for electrons + positrons
              } else if ( idpa == 2 || idpa == 3) {
                //float px = sdata[i + 1];
                //float py = sdata[i + 2];
                //float pz = sdata[i + 3];
                float x  = sdata[i+4];
                float y  = sdata[i+5];
                // float t  = sdata[i+6];

                // Set weights from data block for thinned showers, else set weights to 1.0 for standard showers
                float wEM = isThin ? sdata[i+7] : 1.0;

                double distEM;

                // Distance to shower axis converted to meters, shower axis coords. are defined as (0, 0, 0)
                if ( CurvedObsLevFlag == 1 ) {
                  // If observation level is curved then account for curvature of Earth's surface in distance calculation
                  // Need to define necessary variables first
                  double radEarthPlusObslev = 637131500. + obslev;

                  double theta = sqrt ( x*x + y*y ) / radEarthPlusObslev;
                  double phi = atan2 (y, x);

                  double D = radEarthPlusObslev * sin(theta);

                  double xCart = D * cos(phi);
                  double yCart = D * sin(phi);
                  double zCart = radEarthPlusObslev * cos(theta) - 637131500.;

                  distEM = sqrt ( (xCart - 0.)*(xCart - 0.) + (yCart - 0.)*(yCart - 0.)
                         + (zCart - obslev)*(zCart - obslev) ) / 100. ;           
                } else {
                  // If observation level is not curved then just calculate distance for a flat surface
                  distEM = sqrt ( x*x + y*y - x*x*sin(zenith)*sin(zenith)*cos(azimuth)*cos(azimuth)
                         - y*y*sin(zenith)*sin(zenith)*sin(azimuth)*sin(azimuth)
                         - 2*x*y*sin(zenith)*sin(zenith)*cos(azimuth)*sin(azimuth) ) / 100. ;
                }

                nEM += wEM;

                if ( distEM <= 50. ) {
                  nEMDist50 += wEM;
                }

                if ( distEM <= 100. ) {
                  nEMDist100 += wEM;
                }

                if ( distEM <= 150. ) {
                  nEMDist150 += wEM;
                }

                if ( distEM <= 200. ) {
                  nEMDist200 += wEM;
                }

                if ( distEM <= 250. ) {
                  nEMDist250 += wEM;
                }

                if ( distEM <= 300. ) {
                  nEMDist300 += wEM;
                }

                if ( distEM <= 350. ) {
                  nEMDist350 += wEM;
                }

                if ( distEM <= 400. ) {
                  nEMDist400 += wEM;
                }

                if ( distEM <= 450. ) {
                  nEMDist450 += wEM;
                }

                if ( distEM <= 500. ) {
                  nEMDist500 += wEM;
                }

                if ( distEM <= 550. ) {
                  nEMDist550 += wEM;
                }

                if ( distEM <= 600. ) {
                  nEMDist600 += wEM;
                }

                if ( distEM <= 650. ) {
                  nEMDist650 += wEM;
                }

                if ( distEM <= 700. ) {
                  nEMDist700 += wEM;
                }

                if ( distEM <= 750. ) {
                  nEMDist750 += wEM;
                }

                if ( distEM <= 800. ) {
                  nEMDist800 += wEM;
                }

                if ( distEM <= 850. ) {
                  nEMDist850 += wEM;
                }

                if ( distEM <= 900. ) {
                  nEMDist900 += wEM;
                }

                if ( distEM <= 950. ) {
                  nEMDist950 += wEM;
                }

                if ( distEM <= 1000. ) {
                  nEMDist1000 += wEM;
                }


              } else {
                continue;
              }
            }
          }
        }
        /// end of the record
        if ( !getBinary( sdata[21 * nsblstd + 1], isThin ) ) {
          cerr << "This file is corrupted, this is not a record length - end of block!" << endl;
          BROKENflag = true;
          break;
        }
      }

      // Round the number of particles to nearest integer, since weights can be fractional in thinned showers
      nMuons = round(nMuons);
      nMuons1 = round(nMuons1);
      nMuons500 = round(nMuons500);
      nMuons1000 = round(nMuons1000);

      thinWeight1 = round(thinWeight1);
      thinWeight500 = round(thinWeight500);

      nMuDist50 = round(nMuDist50);
      nMuDist100 = round(nMuDist100);
      nMuDist150 = round(nMuDist150);
      nMuDist200 = round(nMuDist200);
      nMuDist250 = round(nMuDist250);
      nMuDist300 = round(nMuDist300);
      nMuDist350 = round(nMuDist350);
      nMuDist400 = round(nMuDist400);
      nMuDist450 = round(nMuDist450);
      nMuDist500 = round(nMuDist500);
      nMuDist550 = round(nMuDist550);
      nMuDist600 = round(nMuDist600);
      nMuDist650 = round(nMuDist650);
      nMuDist700 = round(nMuDist700);
      nMuDist750 = round(nMuDist750);
      nMuDist800 = round(nMuDist800);
      nMuDist850 = round(nMuDist850);
      nMuDist900 = round(nMuDist900);
      nMuDist950 = round(nMuDist950);
      nMuDist1000 = round(nMuDist1000);

      nEM = round(nEM);

      nEMDist50 = round(nEMDist50);
      nEMDist100 = round(nEMDist100);
      nEMDist150 = round(nEMDist150);
      nEMDist200 = round(nEMDist200);
      nEMDist250 = round(nEMDist250);
      nEMDist300 = round(nEMDist300);
      nEMDist350 = round(nEMDist350);
      nEMDist400 = round(nEMDist400);
      nEMDist450 = round(nEMDist450);
      nEMDist500 = round(nEMDist500);
      nEMDist550 = round(nEMDist550);
      nEMDist600 = round(nEMDist600);
      nEMDist650 = round(nEMDist650);
      nEMDist700 = round(nEMDist700);
      nEMDist750 = round(nEMDist750);
      nEMDist800 = round(nEMDist800);
      nEMDist850 = round(nEMDist850);
      nEMDist900 = round(nEMDist900);
      nEMDist950 = round(nEMDist950);
      nEMDist1000 = round(nEMDist1000);

      cout << nMuons << " " << nMuons1 << " " << nMuons500 << " " << nMuons1000 << " "
           << muonThin1 << " " << thinWeight1 << " " << muonThin500 << " " << thinWeight500 << " "
           << nMuDist50 << " " << nMuDist100 << " " << nMuDist150 << " " << nMuDist200 << " "
           << nMuDist250 << " " << nMuDist300 << " " << nMuDist350 << " " << nMuDist400 << " "
           << nMuDist450 << " " << nMuDist500 << " " << nMuDist550 << " " << nMuDist600 << " "
           << nMuDist650 << " " << nMuDist700 << " " << nMuDist750 << " " << nMuDist800 << " "
           << nMuDist850 << " " << nMuDist900 << " " << nMuDist950 << " " << nMuDist1000 << " "
           << nEM << " " << nEMDist50 << " " << nEMDist100 << " " << nEMDist150 << " " << nEMDist200 << " "
           << nEMDist250 << " " << nEMDist300 << " " << nEMDist350 << " " << nEMDist400 << " "
           << nEMDist450 << " " << nEMDist500 << " " << nEMDist550 << " " << nEMDist600 << " "
           << nEMDist650 << " " << nEMDist700 << " " << nEMDist750 << " " << nEMDist800 << " "
           << nEMDist850 << " " << nEMDist900 << " " << nEMDist950 << " " << nEMDist1000 << endl;

      if ( BROKENflag || !(EVTEcnt == nrShow) ) {
        cerr << "Files is broken: not enough EVTE or garbage word is wrong " << file_ << endl;
        break;
      }
      is.close();
    }
  }
  return 0;
}


