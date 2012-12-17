<%@ include file="common.jspf" %>

<%
	ProcessViewer procViewer = client.getProcessViewer();

%>



<html>
<head>
<title>Dataset Form</title>
</head>
<body>

<%
	Dataset dataset = client.getProcessViewer().getSelectedDataset();
	Target target = dataset.getTargetObj();
	int month = dataset.getMonth();
	int day = dataset.getDay();
	int year = dataset.getYear();
%>

<form name="datasetForm" method="POST" action="SaveDataset.do" target="_parent">
<input type="hidden" name="name" value="<%= dataset.getName() %>" />
<input type="hidden" name="file" value="<%= dataset.getFile() %>" />

<div align="center"><center>

<table BORDER="1" width="90%" bgcolor="FFFF99">
<tr><th align="left" bgcolor="FFCC00" colspan="2"><b>Dataset Definition</b></th></tr>
<tr>
      <th width="20%" nowrap>Dataset Name:</th>
      <td width="80%"><%= dataset.getName() %></td>
</tr>
<tr>
      <th width="20%" nowrap>Definition file:</th>
      <td width="80%"><%= dataset.getFile() %></td>
</tr>
</table>

<br>

<table border="1" width="90%" bgcolor="#FFFF99">
<tr><th align="left" bgcolor="FFCC00" colspan="2"><b>Target Data</b></th></tr>
<tr>
      <th width="20%" nowrap>Target name:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getName() %>"
                             name="target" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Residues:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getResidues() %>"
                             name="residues" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Molecular Weight:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getMolecularWeight() %>"
                             name="molecularWeight" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Oligomerization:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getOligomerization() %>"
                             name="oligomerization" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Hash Semet:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getHasSemet() %>"
                             name="hasSemet" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Heavy Atom:</th>
      <td width="80%">Name: <input type="TEXT"
                             value="<%= target.getHeavyAtom1() %>"
                             name="heavyAtom1" SIZE="10">
                      Number: <input type="TEXT"
                             value="<%= target.getHeavyAtom1Count() %>"
                             name="heavyAtom1Count" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Heavy Atom:</th>
      <td width="80%">Name: <input type="TEXT"
                             value="<%= target.getHeavyAtom2() %>"
                             name="heavyAtom2" SIZE="10">
                      Number: <input type="TEXT"
                             value="<%= target.getHeavyAtom2Count() %>"
                             name="heavyAtom2Count" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Heavy Atom:</th>
      <td width="80%">Name: <input type="TEXT"
                             value="<%= target.getHeavyAtom3() %>"
                             name="heavyAtom3" SIZE="10">
                      Number: <input type="TEXT"
                             value="<%= target.getHeavyAtom3Count() %>"
                             name="heavyAtom3Count" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Heavy Atom:</th>
      <td width="80%">Name: <input type="TEXT"
                             value="<%= target.getHeavyAtom4() %>"
                             name="heavyAtom4" SIZE="10">
                      Number: <input type="TEXT"
                             value="<%= target.getHeavyAtom4Count() %>"
                             name="heavyAtom4Count" SIZE="10"></td>
</tr>
<tr>
      <th width="20%" nowrap>Sequence Header:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getSequenceHeader() %>"
                             name="sequenceHeader" SIZE="70"></td>
</tr>
<tr>
      <th width="20%" nowrap>Sequence Prefix:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= target.getSequencePrefix() %>"
                             name="sequencePrefix" SIZE="70"></td>
</tr>
<tr>
      <th width="20%" nowrap>Sequence:</th>
      <td width="80%"><textarea ROWS="5" cols="70" name="sequence"><%= target.getSequence() %></textarea></td>
</tr>
</table>


<br>

<table BORDER="1" width="90%" bgcolor="FFFF99">
<tr><th align="left" bgcolor="FFCC00" colspan="2"><b>Collected Data</b></th></tr>

<tr>
      <th width="20%" nowrap>Date Data Collected:</th>
      <td width="80%">

<select name="month" SIZE="1">

<%	for (int i = 1; i < 13; ++i) {
		if (i == month) { %>
			<option value='<%= i %>' selected><%= i %></option>
		<% } else { %>
			<option value='<%= i %>'><%= i %></option>
		<% }
	} %>

</select>

<select name="day" SIZE="1">

<%	for (int i = 1; i < 32; ++i) {
		if (i == day) { %>
			<option value='<%= i %>' selected><%= i %></option>
		<% } else { %>
			<option value='<%= i %>'><%= i %></option>
		<% }
	} %>

</select>

<select name="year" SIZE="1">

<%	for (int i = 1998; i < 2010; ++i) {
		if (i == year) { %>
			<option value='<%= i %>' selected><%= i %></option>
		<% } else { %>
			<option value='<%= i %>'><%= i %></option>
		<% }
	} %>

</select>
</td>
</tr>
<tr>
<th width="20%" nowrap>Beamline:</th>
<td width="80%">

<select name="beamline" SIZE="1" >
<%

	int num = 19;
	String b[] = new String[num];
	b[0] = "undefined";
	b[1] = "BL1_5";
	b[2] = "BL9_1";
	b[3] = "BL9_2";
	b[4] = "BL11_1";
	b[5] = "BL11_3";
	b[6] = "ALS_BL5.0.1";
	b[7] = "LS_BL5.0.2";
	b[8] = "ALS_BL5.0.3";
	b[9] = "ALS_BL8.2.1";
	b[10] = "ALS_BL8.2.2";
	b[11] = "ALS_BL8.3.1";
	b[12] = "bioCARS_BM_C";
	b[13] = "bioCARS_BM_D";
	b[14] = "bioCARS_ID_B";
	b[15] = "SBC_19BM";
	b[16] = "SBC_19ID";
	b[17] = "NE_CAT_8BM";
	b[18] = "Other";

	String n[] = new String[num];
	n[0] = "-select-";
	n[1] = "BL1_5";
	n[2] = "BL9_1";
	n[3] = "BL9_2";
	n[4] = "BL11_1";
	n[5] = "BL11_3";
	n[6] = "ALS BL5.0.1";
	n[7] = "ALS BL5.0.2";
	n[8] = "ALS BL5.0.3";
	n[9] = "ALS BL8.2.1";
	n[10] = "ALS BL8.2.2";
	n[11] = "ALS BL8.3.1";
	n[12] = "bioCARS BM-C";
	n[13] = "bioCARS BM-D";
	n[14] = "bioCARS ID-B";
	n[15] = "SBC 19BM";
	n[16] = "SBC 19ID";
	n[17] = "NE CAT 8BM";
	n[18] = "Other";

	for (int i = 0; i < num; ++i) {
		if (b[i].equals(dataset.getBeamline()))
			out.println("<option value='" + b[i] + "' selected>" + n[i] + "</option>\n");
		else
			out.println("<option value='" + b[i] + "'>" + n[i] + "</option>\n");
	}
%>
</select>
</td>
</tr>
    <tr>
      <th width="20%" nowrap>Target:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getTarget() %>"
                             name="target" SIZE="20"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Crystal ID:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getCrystalId() %>"
                             name="crystalId" SIZE="20"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Experiment:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getExperiment() %>"
                             name="experiment" SIZE="10"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Resolution:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getResolution() %>"
                             name="resolution" SIZE="10"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Data collected by:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getCollectedBy() %>"
                             name="collectedBy" SIZE="10"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Image Directory:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getDirectory() %>"
                             name="directory" SIZE="70"></td>
    </tr>


<input type="HIDDEN" value="<%= dataset.getXFileDirectory() %>" name="xFiledDrectory"/>
    <tr>
      <th width="20%" nowrap>Beam Centre:</th>
      <td width="80%">
		beamX: <input type="TEXT" value="<%= dataset.getBeamX() %>" name="beamX" SIZE="8"/>
		beamY: <input type="TEXT" value="<%= dataset.getBeamY() %>" name="beamY" SIZE="8"/>
	  </td>
    </tr>
    <tr>
      <th width="20%" nowrap>Autoindex Images:</th>
      <td width="80%">
		prefix: <input type="TEXT" value="<%= dataset.getAutoindexIdent() %>" name="autoindexIdent" SIZE="20"/>
		image1: <input type="TEXT" value="<%= dataset.getAutoindex1() %>" name="autoindex1" SIZE="4"/>
		image2: <input type="TEXT" value="<%= dataset.getAutoindex2() %>" name="autoindex2" SIZE="4"/>
	  </td>
    </tr>
    <tr>
      <th width="20%" nowrap>Lambda1:</th>
      <td width="80%">
		fprimv: <input type="TEXT" value="<%= dataset.getFprimv1() %>" name="fprimv1" SIZE="5"/>
		fprprv: <input type="TEXT" value="<%= dataset.getFprprv1() %>" name="fprprv1" SIZE="5"/>
		prefix list: <input type="TEXT" value="<%= dataset.getImg1() %>" name="img1" SIZE="50"/>
      </td>
    </tr>
    <tr>
      <th width="20%" nowrap>Lambda2:</th>
      <td width="80%">
		fprimv: <input type="TEXT" value="<%= dataset.getFprimv2() %>" name="fprimv2" SIZE="5"/>
		fprprv: <input type="TEXT" value="<%= dataset.getFprprv2() %>" name="fprprv2" SIZE="5"/>
		prefix list: <input type="TEXT" value="<%= dataset.getImg2() %>" name="img2" SIZE="50"/>
      </td>
    </tr>
    <tr>
      <th width="20%" nowrap>Lambda3:</th>
      <td width="80%">
		fprimv: <input type="TEXT" value="<%= dataset.getFprimv3() %>" name="fprimv3" SIZE="5"/>
		fprprv: <input type="TEXT" value="<%= dataset.getFprprv3() %>" name="fprprv3" SIZE="5"/>
		prefix list: <input type="TEXT" value="<%= dataset.getImg3() %>" name="img3" SIZE="50"/>
      </td>
    </tr>
    <tr>
      <th width="20%" nowrap>Lambda4:</th>
      <td width="80%">
		fprimv: <input type="TEXT" value="<%= dataset.getFprimv4() %>" name="fprimv4" SIZE="5"/>
		fprprv: <input type="TEXT" value="<%= dataset.getFprprv4() %>" name="fprprv4" SIZE="5"/>
		prefix list: <input type="TEXT" value="<%= dataset.getImg4() %>" name="img4" SIZE="50"/>
      </td>
    </tr>


    <tr>
      <th width="20%" nowrap>Spacegroup list:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getSpacegroup() %>"
                             name="spacegroup" SIZE="70"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Number of molecules:</th>
      <td width="80%"><input type="TEXT"
                             value="<%= dataset.getNmol() %>"
                             name="nmol" SIZE="70"></td>
    </tr>
    <tr>
      <th width="20%" nowrap>Comment:</th>
      <td width="80%">
      <textarea ROWS="5" cols="70" name="myComment"><%= dataset.getMyComment() %></textarea></td>
    </tr>
  </table>

<br>
<input type="SUBMIT" value="Save" id=SUBMIT1 name=SUBMIT1>
<input type="RESET" value="Reset" id=RESET1 name=RESET1>

</center></div>

</form>



</body>
</html>
