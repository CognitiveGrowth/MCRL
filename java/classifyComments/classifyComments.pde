import rita.*;
import net.sf.extjwnl.JWNLException;
import net.sf.extjwnl.data.IndexWord;
import net.sf.extjwnl.data.POS;
import net.sf.extjwnl.data.PointerType;
import net.sf.extjwnl.data.PointerUtils;
import net.sf.extjwnl.data.list.PointerTargetNodeList;
import net.sf.extjwnl.data.list.PointerTargetTree;
import net.sf.extjwnl.data.relationship.AsymmetricRelationship;
import net.sf.extjwnl.data.relationship.Relationship;
import net.sf.extjwnl.data.relationship.RelationshipFinder;
import net.sf.extjwnl.data.relationship.RelationshipList;
import net.sf.extjwnl.dictionary.Dictionary;
import net.sf.extjwnl.data.Synset;
import net.sf.extjwnl.data.list.PointerTargetNode;
import net.sf.extjwnl.data.Word;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.List;


/* --------------------------------------------------------------------------------------------------------------------

Usage instructions

1. Preparing input

    The data has to be in a text file with tab-separated columns, specified by [commentsFileName]
    For an example see : data_examples/decisions.csv 
    The data consists of numerical labels (e.g. 0, 1) and comments. Any other columns in [commentsFileName] will be ignored
    
    The "comments" are verbal responses generated by subjects to questions such as "How did you plan your decisions?" or "Would you eat alien ice-cream?" etc.
    
    Numerical labels are provided by the user. 
    For example, suppose that we want to see the words that subjects chose given that they who were more or less likley to be optimal.
    The subjects have a mode-based score of how likely one is to act optimally, which is a real number. 
    
    So, we split the subjects to more optimal and less optimal by a median split. Suppose the median is 0.83. 
    Then the comemnts of all subjects whose optimality score is <= 0.83 are lebelled 0 
    and those whose optimality score is > 0.83 are labelled 1.
    
    Some labels will be inconsistent, for example some subjects who are highly optimal make contradictory verbal comments 
    saying `I just felt what to do'. That is okay. The purpose of this method is to see if there is any pattern
    in the comments correlated with our model-based metric.
    
    For an example of an input file see : data_examples/decisions.csv 
    For an example of an input file file where the labels are assigned to comments at random : data_examples/loremipsum.csv 

1. Running the tool

    This tool requires Processing and java libraries: extjwnl and RiTa which can be downloaded from the internet
    
    Simply run the program, whih will render a decision tree. If the tree looks cluttered, 
    use mouse to drag the tree nodes around.

-------------------------------------------------------------------------------------------------------------------- */


/* --------------------------------------------------------------------------------------------------------------------
Notes: 

1. 
Currently the code handles only two types of labels (e.g. yes-no). If the classification has more then two labels
you will need to eitehr train a tree for each label or amend the code.

-------------------------------------------------------------------------------------------------------------------- */



/* --------------------------------------------------------------------------------------------------------------------

Related work and ideas for improvements:   

1.
There are commercial tools for black-box classifying app reviews, see if they have any useful features:
https://www.quora.com/Who-are-the-main-competitors-to-the-Google-Prediction-API

2. Standford CORE NLP has sentiment analyis, see if any of its functions can be of use

    
3. Future work: 
The shape of the tree structure ought to predict the strength of the pattern. 
A tree with a long list of disjunctions, such as are trees generated from random data, is likely random. 
But most real life trees will heve long tails of `outliers', or in other words people being original. It woudl be nice
to have a way of automatically classifying trees based on their shape. If this is possible then the algorithm can generate all sorts of 
permutations of labels at random, train the trees on each permutation, and as an output show the user the top least random-looking trees. 
Sure, the procedure will pick up a lot of silly false correlations (which machine learnig already does), but if someone was 
interested the procedure could be further refined toward more relevance. 
-------------------------------------------------------------------------------------------------------------------- */

Dictionary dictionary = null;
StringDict synsDic = null;  

int MINIMAL_FREQUENCY_SYNONYM = 5;

RiTa rita;
RiWordNet wordnet; 
RiLexicon rilex;
RiString rs;

String text = "";
Tree T;  // the structure contining the whole decision tree


/* --------------------------------------------------------------------------------------------------------------------

The most important part.  If you change the commentsFileName, please also change indexOfCommentColumn and indexOfLabelColumn

-------------------------------------------------------------------------------------------------------------------- */

int indexOfCommentColumn = 1;    
int indexOfLabelColumn = 4;
int indexOfSubjectColumn = 0;

int commentsPreprocessedCommentIndex = 2;
int commentsPreprocessedLabelIndex = 1;

String commentsFileName = "data_examples/final.csv";   // input

int YesLabel = 1;
String YesText = "label1";  // Label text as will be displayed in the tree. You can change the label text, e.g. to "yes" and "no"
String NoText = "other";

boolean replaceByCommonSynonyms = false; // Whether to try to use wordnet to reduce the word-feature space by replacing words by their most common synonym.
                                         // In practice most common synonym is rarely the right word!
                                         // This is more likly to work with a sense disambiguation processing instead of taking the most common sense of the word, 
                                         // as described here: https://en.wikipedia.org/wiki/Lesk_algorithm
                                         // However, current approaches to sense disambiguation apply to large data-sets only.
                                          
boolean joinByCommmonSynonyms = false;    // Whether to try to use wordnet to join two word features if they have common synonyms
                                          // In practice this reduces the feature space, but introduces too much noise. 
                                          
                                         

// --------------------------------------------------------------------------------------------------------------------



String commentsPreprocessed = "commentscombinedPunctuationRemoved.csv"; // the program will generate pre-processed text 
                                                                        // with all grammar and articles stripped, that the
                                                                        // decision tree is actually trained on

String wordfreqfilename = "wordfreq_combined.txt";                      // a list of all unique words occurring in the text and their frequencies                       
                                                                        // the program will generate this file but you can edit it and combine 
                                                                        // words that should go together

String wordEquivalencefilename = "wordfreq_combined_eqivalence.txt";    // the result of combining equivalent words by wordnet
                                                                        // the program will generate this file



boolean PluralityForYesLabelOnly = true; // when returning plurality judgements do not show majority labels other than Yes/No


// --------------------------------------------------------------------------------------------------------------------
// The list of words that will be ignored, feel free to edit the list
// --------------------------------------------------------------------------------------------------------------------

String[] ignoreList = { "thing", "much", "conclusion", "well", "dont", "get", "too", 
                        "usually", "would", "will", "did", "didnt", "wasnt",
                       "per", "what", "very", "with", "one", "also", "out", "the", 
                       "that", "and", "this", "them", "these", "those", "but", "was", 
                       "are", "you", "for", "how", "not", "since", "some",
                       "then", "have", "which", "use", "none", "may", "might", "once", 
                       "while", "were", "whichever", "along", "could", "make", "give"};
       
// --------------------------------------------------------------------------------------------------------------------
// The list of words that shoudl not be reduced to sysnonyms, feel free to edit the list for your context
// --------------------------------------------------------------------------------------------------------------------

String[] doNotReplaceList = {"think",  "guess", "guessed", "move", "get", "expand", "feel", "clear", "dead-end", "comments", "find"};

int dispxl = 20;
int dispxr = 20;
int dispyl = 70;
int dispyr = 70;
  
float anglel=20;
float angler=15;

int rootX = 200;
int rootY = 200;

Tree nodeSelected = null;

void mouseDragged() {
  if (nodeSelected != null) {
    
    if (nodeSelected == T && T.x == 0) {
      rootX = mouseX;
      rootY = mouseY;
    } else {
      // does not work, the drawing is automatic
      
      int dx = -nodeSelected.x + mouseX;
      int dy = -nodeSelected.y + mouseY;
      
      //nodeSelected.x = mouseX; 
      //nodeSelected.y = mouseY;
      
      moveTree(nodeSelected, dx, dy);
    }
  }
}

void keyPressed() {
  if (key=='=') {
    dispyl++;
    dispyr++;
  } else if (key=='-') {
    dispyl--;
    dispyr--;
  }
} //<>// //<>//

void mouseClicked() {
  // todo: show the list of examples upon clicking on the tree node
  // The Tree class has the root of the tree and, if any, the two branches leafsTrue, leafsFalse
  // add an (x,y) coordinate of the tree to Tree, wihc will be initialised as the tree is being drawn
  // so that the click on the tree will reveal in a popout woindow, or print out, its associated examples
}

void moveTree(Tree t, int dx, int dy) {
  if (t == null) return;
  t.x+=dx;
  t.y+=dy;
  
  moveTree(t.leafsTrue, dx, dy);
  moveTree(t.leafsFalse, dx, dy);
}

Tree get_nodeSelected(Tree t) {
  
  if (t == null) return t;
  
  if ( dist(t.x, t.y, mouseX, mouseY) < 30 ) return t;
  
  Tree t1 = get_nodeSelected(t.leafsTrue);
  if (t1 != null) return t1;
  
  return get_nodeSelected(t.leafsFalse);
}

void mousePressed() {
  // is a tree node selected?
  nodeSelected = get_nodeSelected(T);
  if (nodeSelected != null) {
    fill(255,255,0);
    stroke(255,255,0);
    ellipse(nodeSelected.x, nodeSelected.y,30,30);
    if (nodeSelected != T) {
      // show examples
    }
  }
}

void setup()
{
  println(sketchPath());
  model = new POSModelLoader().load(new File(sketchPath() + "/openNLPDemo/en-pos-maxent.bin"));
  // Load EXTJWNL interface for wordnet
  
  try {
     dictionary = Dictionary.getDefaultResourceInstance();
     if (null == dictionary) {
        println("Could not load extjwnl");
     }
  
  } catch (Exception ex) {
    ex.printStackTrace();
    System.exit(-1);
  }    
    
  // load RiTa wordnet, ignoring compound & uppercase words
  wordnet = new RiWordNet("/Users/luckyfish/Desktop/processing/WordNet-3.0", true /*ignoreCompoundWords*/, true /*ignore uppercase words*/);   
  rita = new RiTa();
  rilex = new RiLexicon();
  
  extractWords();       // word extraction, will create the file specified by [commentsPreprocessed]
  
  // load all comments and their labels
  String [] commentsAndLabels = loadStrings(commentsPreprocessed);
    
  StringList equivalenceDictionary = new StringList();
  println(commentsAndLabels.length, "entries");
  
  String[] s = null;

  if (joinByCommmonSynonyms) {
      
      commonSynonyms();                            // join two word features if they have common synonyms
      s = loadStrings(wordEquivalencefilename);
  } else {
      s = loadStrings(wordfreqfilename);
  }
  
  for (int i = 0; i < s.length; i++) {
        String[] tok = splitTokens(s[i], "\t");
        equivalenceDictionary.append(tok[0].trim());
  } 
  
  for (int c =0; c<commentsAndLabels.length; c++) {
        
    String[] tok = splitTokens(commentsAndLabels[c], "\t");
    if (tok.length <= commentsPreprocessedCommentIndex) {
      println("bad line", tok.length, commentsAndLabels[c]);
      continue; 
    }
    String[] w = splitTokens(tok[commentsPreprocessedCommentIndex], " ");
    
    for (int j=0; j<w.length; j++) {
      String wlowercase = preprocess(w[j]);
      if (wlowercase.length() < 1) continue;
      
      String e = getEquivalent(wlowercase, equivalenceDictionary);
      if (e.length() == 0 || e.equals(wlowercase)) {
        // do nothing
      } else {
        println("replacing ", w[j] , " with ", e);
        commentsAndLabels[c] = commentsAndLabels[c].replaceAll("\\b"+w[j]+"\\b", e);
      }
    }
    
    
    println(commentsAndLabels[c]);    // print out what the classifier will see to make sure we do not get nonesence
        
  }
  
  // classify by a decision tree
  StringList examples = new StringList();
  IntList labels = new IntList();
  
  for (int c =0; c<commentsAndLabels.length; c++) {
      
      // separate the comment from the label
      String[] tok = splitTokens(commentsAndLabels[c], "\t");
      if (tok.length <= commentsPreprocessedCommentIndex) continue;
      
      String comment = tok[commentsPreprocessedCommentIndex];  
      
      println ("reading label " + tok[commentsPreprocessedLabelIndex]);
      
      int label = parseInt(tok[commentsPreprocessedLabelIndex]);
      
      examples.append(comment);
      labels.append(label);
  }
    
  // attributes are all first words from the equivalence dictionary
  StringList attributes = new StringList();
  
  for (int j = 0; j < equivalenceDictionary.size(); j++) {
    String[] tok = splitTokens(equivalenceDictionary.get(j), ",");
    attributes.append(tok[0].trim());
  }
  
  println ("DEBUG INFO, examples");
  for (String ex : examples) {
    println(ex);
  }
  
   println ("DEBUG INFO, labels");
  for (int l : labels) {
    println("label " + l);
  }
  
   println ("DEBUG INFO, labels");
  for (String a : attributes) {
    print(", " + a);
  }
  
  T = trainTheTree(examples, labels, null, null, attributes );

  size(1000, 750);   

  //noLoop() ;
  //RiTa.timer(this, 0.5f);
}

void draw() {
  fill(0);
  textSize(15);
  background(255);  
  
  if (T.x == 0 && T.y == 0) {
    pushMatrix();
    translate(rootX, rootY);
    drawTree(T);
    popMatrix();
  } else {
    drawTreebyCoords(T);
  }
}

void drawTreebyCoords(Tree t) {
  if (t != null) {
    if (t.attribute !=null) {
      fill(0);
      if (t.attribute.gain > 0) {
        textSize(15+t.attribute.gain*10);
      } else {
        textSize(15);
      }
      text(t.attribute.name, -4*t.attribute.name.length() + t.x,  t.y);
  
      String chis =  nf(t.attribute.chi_square, 2, 2);
      String df = nf(t.attribute.dof, 2, 0); 
      
      if (t.attribute.chi_square < 10) chis =  nf(t.attribute.chi_square, 1, 2);
      if (t.attribute.dof < 10) df = nf(t.attribute.dof, 1, 0); 
      
      text("(" + chis + ", " + df + ")", -4*t.attribute.name.length() + t.x, 15 + t.y);
      
      stroke(0,200,0);
      line(t.x,t.y, t.leafsTrue.x, t.leafsTrue.y);
      drawTreebyCoords(t.leafsTrue);
     
      stroke(200,0,0);
      line(t.x,t.y, t.leafsFalse.x, t.leafsFalse.y);
      drawTreebyCoords(t.leafsFalse);
    } else {
      textSize(15);
      fill(0, 102, 153);
      stroke(0,0,255);
      
      int s = 0;
      if (t.examplesYes != null) s += t.examplesYes.size();
      if (t.examplesNo != null) s += t.examplesNo.size();
      
      if (t.label == YesLabel) {
        text(YesText + "," + s, t.x-15, t.y+5);
      } else {
        text(NoText + "," + s, t.x-15,t.y+5);
      }
    }
  } 
}

void drawTree(Tree t) {

  if (t != null) {
    if (t.attribute !=null) {
      fill(0);
      if (t.attribute.gain > 0) {
        textSize(15+t.attribute.gain*10);
      } else {
        textSize(15);
      }
      text(t.attribute.name, -4*t.attribute.name.length(), 0);
      
      t.x = (int)screenX(0, 0);
      t.y = (int)screenY(0, 0);
  
      String chis =  nf(t.attribute.chi_square, 2, 2);
      String df = nf(t.attribute.dof, 2, 0); 
      
      if (t.attribute.chi_square < 10) chis =  nf(t.attribute.chi_square, 1, 2);
      if (t.attribute.dof < 10) df = nf(t.attribute.dof, 1, 0); 
      
      text("(" + chis + ", " + df + ")", -4*t.attribute.name.length(), 15);
      
      pushMatrix();
      stroke(0,200,0);
      rotate(radians(anglel));
      line(0,0,-dispxl,dispyl);
      translate(-dispxl, dispyl);
      drawTree(t.leafsTrue);
      //translate(dispxl, -dispyl);
      popMatrix();
      
      pushMatrix();
      stroke(200,0,0);
      rotate(radians(-angler));
      line(0,0, dispxr,dispyr);
      translate(dispxr, dispyr);
      drawTree(t.leafsFalse);
      popMatrix();
    } else {
      textSize(15);
      fill(0, 102, 153);
      stroke(0,0,255);
      
      int s = 0;
      if (t.examplesYes != null) s += t.examplesYes.size();
      if (t.examplesNo != null) s += t.examplesNo.size();
      
      t.x = (int)screenX(0, 0);
      t.y = (int)screenY(0, 0);
      
      if (t.label == YesLabel) {
        text(YesText + "," + s, -15,5);
      } else {
        text(NoText + "," + s, -15,5);
      }
    }
  } 
  
}