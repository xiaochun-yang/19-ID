package sil.test;

import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.File;
import java.io.IOException;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import org.apache.xml.serializer.Serializer;
import org.apache.xml.serializer.SerializerFactory;
import org.apache.xml.serializer.OutputPropertiesFactory;

import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import java.io.FileReader;

public class TransformTest
{

	public static void main(String[] args)
	{
		try {

		if (args.length != 2) {
			System.out.println("Usage: sil.test.TransformTest <xml file> <xsl file>");
			System.exit(0);
		}

		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer( new StreamSource(args[1]));
//    	transformer.setParameter("param1", "penjitk");

		StreamSource source = new StreamSource( new FileReader(args[0]));
		StreamResult result = new StreamResult(System.out);
		transformer.transform(source, result);


		} catch (Exception e) {
			e.printStackTrace();
		}

	}

}