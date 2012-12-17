package sil.beans;

import java.io.*;
import java.util.*;

import org.w3c.dom.*;
import org.xml.sax.*;
import javax.xml.transform.stream.*;
import javax.xml.parsers.*;

import jxl.Workbook;
import jxl.WorkbookSettings;
import jxl.write.*;
import jxl.format.Font;
import jxl.format.Alignment;

import java.net.URL;

/**************************************************
 *
 * HeaderData
 *
 **************************************************/
class HeaderData
{
	String name;
	int width;
	String readOnly;
	String hide;

	HeaderData(String n1, int n2, String n3, String n4)
	{
		name = n1;
		width = n2;
		hide = n3;
		readOnly = n4;
	}
}

