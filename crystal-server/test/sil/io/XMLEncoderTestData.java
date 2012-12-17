package sil.io;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Vector;

public class XMLEncoderTestData {
	private List<String> list1 = new ArrayList<String>();
	private List<String> list2 = Collections.synchronizedList(new ArrayList<String>());
	private List<String> list3 = new Vector<String>();
	
	public List<String> getList1() {
		return list1;
	}
	public void setList1(List<String> list1) {
		this.list1 = list1;
	}
	public List<String> getList2() {
		return list2;
	}
	public void setList2(List<String> list2) {
		this.list2 = list2;
	}
	public List<String> getList3() {
		return list3;
	}
	public void setList3(List<String> list3) {
		this.list3 = list3;
	}
	
	public void addToList1(String str) {
		list1.add(str);
	}
	
	public void addToList2(String str) {
		list2.add(str);
	}
	
	public void addToList3(String str) {
		list3.add(str);
	}
}
