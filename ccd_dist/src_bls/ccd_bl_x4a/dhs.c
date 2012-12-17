int	get_current_wavelength_from_control(double *wp)
{
	int	fd;
	int	buflen;
	char	buf[100];
	char	*cp;
	float	new_energy, new_wavelength;

	if(local_control_port == -1)
		return(-1);

	if(-1 == (fd = connect_to_host_api(&fd, local_control_host, local_control_port, NULL)))
	{
		fprintf(stderr,"get_current_wavelength_from_control: connection to host %s port %d was refused\n",
			local_control_host, local_control_port);
		perror("get_current_wavelength_from_control");
		return(-1);
	}

	sprintf(buf, "getenergy\n");
	buflen = strlen(buf);
	if(-1 == rep_write(fd, buf, buflen))
	{
		close(fd);
		return(-1);
	}
	if(0 >= read_until(fd, buf, sizeof buf, "done"))
	{
		close(fd);
		return(-1);
	}
	if(NULL == (cp = strstr(buf, "error")))
	{
		sscanf(buf, "%f", &new_energy);
		new_wavelength = EV_ANGSTROM / new_energy;
		*wp = new_wavelength;
		fprintf(stderr,"get_current_wavelength_from_control: got wavelength: %.6f\n", new_wavelength);
		close(fd);
		return(0);
	}
	fprintf(stderr,"get_current_wavelength_from_control: Error setting wavelength: buf: %s\n", buf);
	close(fd);
	return(-1);
}

int	send_wavelength_request_to_control(double *wp, char *err_msg)
{
	int	fd;
	int	buflen;
	char	buf[100];
	char	*cp, *cp2;
	float	new_energy, new_wavelength;

	*err_msg = '\0';

	if(local_control_port == -1)
		return(-1);

	if(-1 == (fd = connect_to_host_api(&fd, local_control_host, local_control_port, NULL)))
		return(-1);

	new_energy = EV_ANGSTROM / *wp;
	sprintf(buf, "moveenergy %.3f 1\n", new_energy);
	buflen = strlen(buf);
	if(-1 == rep_write(fd, buf, buflen))
	{
		close(fd);
		return(-1);
	}
	if(0 >= read_until(fd, buf, sizeof buf, "done"))
	{
		close(fd);
		return(-1);
	}
	if(NULL == (cp = strstr(buf, "error")))
	{
		sscanf(buf, "%f", &new_energy);
		new_wavelength = EV_ANGSTROM / new_energy;
		*wp = new_wavelength;
		close(fd);
		return(0);
	}
	fprintf(stderr,"send_wavelength_request_to_control: Error setting wavelength: buf: %s\n", buf);
	close(fd);
	return(-1);
}
