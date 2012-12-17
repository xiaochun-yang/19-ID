void	bzero(p,n)
char	*p;
int	n;
  {
	int	i;
	for(i = 0; i < n; i++)
		p[i] = 0;
  }
