/*
 * testSwing.java
 *
 * Created on August 22, 2003, 4:11 PM
 */

/**
 *
 * @author  jsong
 */
import javax.swing.*;
import javax.swing.text.*;

import java.awt.*;              //for layout managers
import java.awt.event.*;        //for action and window events

public class DCSSWindow extends javax.swing.JFrame implements ActionListener {
    
    private JTextArea textArea = new JTextArea(25, 80);
    
    /** Creates a new instance of testSwing */
    public DCSSWindow() {
        super("DCSSConnection");

        //Create a text area.
        
        textArea.setEditable(false);
        
        textArea.setFont(new Font("Monospaced", Font.PLAIN, 12));
        //textArea.setLineWrap(true);
        //textArea.setWrapStyleWord(true);
        JScrollPane areaScrollPane = new JScrollPane(textArea);
        areaScrollPane.setVerticalScrollBarPolicy(
                        JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        //areaScrollPane.setPreferredSize(new Dimension(250, 250));
        areaScrollPane.setBorder(
            BorderFactory.createCompoundBorder(
                BorderFactory.createCompoundBorder(
                                BorderFactory.createTitledBorder("DCSS CONNECTION"),
                                BorderFactory.createEmptyBorder(5,5,5,5)),
                areaScrollPane.getBorder()));
        
        
        //JPanel leftPane = new JPanel();
        //BoxLayout leftBox = new BoxLayout(leftPane, BoxLayout.Y_AXIS);
        //leftPane.setLayout(leftBox);
        //leftPane.add(areaScrollPane);        
        //setContentPane( leftPane );
        setContentPane( areaScrollPane );
    }
    
    public void print( String message ) {
        textArea.append(message+"\n");
    }
    
    public JTextArea getTextArea( ) {
        return textArea;
    }
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        DCSSWindow frame = new DCSSWindow();

        frame.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });

        frame.pack();
        frame.setVisible(true);
        
        frame.print("DCSS CONNECTION WINDWOS\nGasdf asldfj adsl\nasdfasdfasdf");
        
    }
    
    public void actionPerformed(ActionEvent e) {
    }    
}
