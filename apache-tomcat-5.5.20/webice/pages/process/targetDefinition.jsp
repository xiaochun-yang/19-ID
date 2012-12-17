<%@ include file="common.jspf" %>


<HTML>
<HEAD>
<TITLE>Target Form</TITLE>
</HEAD>
<BODY>

<h2>Target Definition</h2>

<%
	Dataset dataset = client.getProcessViewer().getSelectedDataset();
	Target target = target.getTarget();
	int num = target.getNumHeavyAtomTypesAllowed();
%>


<FORM NAME="targetForm" METHOD="POST" ACTION="SaveTarget.do" target="_parent">
<input type="hidden" name="name" value="<%= target.getName() %>" />
<input type="hidden" name="file" value="<%= target.getFile() %>" />

<DIV ALIGN="CENTER"><CENTER>
<TABLE BORDER="1" WIDTH="90%">
    <TR>
      <TH WIDTH="20%" NOWRAP>Target:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getName() %>"
                             NAME="target" SIZE="20"></TD>
    </TR>
	<TR>
		  <TH WIDTH="20%" NOWRAP>Definition file:</TH>
		  <TD WIDTH="80%"><%= target.getFile() %></TD>
	</TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Number of Residues:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getResidues() %>"
                             NAME="residues" SIZE="20"></TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Molecuar Weight:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getMolecularWeight() %>"
                             NAME="molecularWeight" SIZE="20"></TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Oligomerization:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getOligomerization() %>"
                             NAME="oligomerization" SIZE="20"></TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Oligomerization:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getHasSemet() %>"
                             NAME="hasSemet" SIZE="20"></TD>
    </TR>

    <TR>
      <TH WIDTH="20%" NOWRAP>Heavy Atom:</TH>
      <TD WIDTH="80%">Name:<INPUT TYPE="TEXT"
                             VALUE="<%= target.getHeavyAtom1() %>"
                             NAME="heavyAtom1" SIZE="20">
                      Number:<INPUT TYPE="TEXT"
					         VALUE="<%= target.getHeavyAtom1Count() %>"
                             NAME="heavyAtom1Count" SIZE="20">
      </TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Heavy Atom:</TH>
      <TD WIDTH="80%">Name:<INPUT TYPE="TEXT"
                             VALUE="<%= target.getHeavyAtom2() %>"
                             NAME="heavyAtom2" SIZE="20">
                      Number:<INPUT TYPE="TEXT"
					         VALUE="<%= target.getHeavyAtom2Count() %>"
                             NAME="heavyAtom2Count" SIZE="20">
      </TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Heavy Atom:</TH>
      <TD WIDTH="80%">Name:<INPUT TYPE="TEXT"
                             VALUE="<%= target.getHeavyAtom3() %>"
                             NAME="heavyAtom3" SIZE="20">
                      Number:<INPUT TYPE="TEXT"
					         VALUE="<%= target.getHeavyAtom3Count() %>"
                             NAME="heavyAtom3Count" SIZE="20">
      </TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Heavy Atom:</TH>
      <TD WIDTH="80%">Name:<INPUT TYPE="TEXT"
                             VALUE="<%= target.getHeavyAtom4() %>"
                             NAME="heavyAtom4" SIZE="20">
                      Number:<INPUT TYPE="TEXT"
					         VALUE="<%= target.getHeavyAtom4Count() %>"
                             NAME="heavyAtom4Count" SIZE="20">
      </TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Sequence Header:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getSequenceHeader() %>"
                             NAME="sequenceHeader" SIZE="20"></TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Sequence Prefix:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getSequencePrefix() %>"
                             NAME="sequencePrefix" SIZE="20"></TD>
    </TR>
    <TR>
      <TH WIDTH="20%" NOWRAP>Sequence:</TH>
      <TD WIDTH="80%"><INPUT TYPE="TEXT"
                             VALUE="<%= target.getSequence() %>"
                             NAME="sequence" SIZE="20"></TD>
    </TR>
  </TABLE>
        <INPUT TYPE="SUBMIT" VALUE="Save" id=SUBMIT1 name=SUBMIT1>
        <INPUT TYPE="RESET" VALUE="Reset" id=RESET1 name=RESET1>
  </CENTER></DIV>
</FORM>


</BODY>
</HTML>
