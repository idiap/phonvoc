/*=======================*/
/* Legendre_Stylizer     */
/*=======================*/
/* Input                 */
/*   Pitch file (.lf0)   */
/*   Label file (.lab)   */
/* --------------------- */
/* Output                */
/*   Target file (.tgt)  */
/*=======================*/
/* M. Cernak, Jan. 2016  */
/* Xingyu Na, Jan. 2013  */
/*=======================*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define MAX_LEN 1024
#define ORDER 3
/* #define FRAME_LEN 50000 */
/* #define FRAME_LEN 100000 */
#define FRAME_LEN 1

static float fmini(float *seq, int size) {
	int i;
	float minimum = 1e+8;

	for (i = 0; i < size; i++)
		if (seq[i] < minimum)
			minimum = seq[i];

	return minimum;
}

static float fmaxi(float *seq, int size) {
	int i;
	float maximum = -1e+8;

	for (i = 0; i < size; i++)
		if (seq[i] > maximum)
			maximum = seq[i];

	return maximum;
}

static float fmean(float *seq, int size) {
	int i, count;
	float mean = 0.0;

	count = 0;
	for (i = 0; i < size; i++)
		if (seq[i] > 0) {
			count++;
			mean += seq[i];
		}

	return mean / count;
}

void kalman(float *obs, int duration) {
	int i;
	float predictor, J, initial, means;
	float *obsVar, initMean, initVar, seqVar, *stateMean, *stateVar;

	/* Initialise */
	means = fmean(obs, duration);
	obsVar = (float *) calloc(duration, sizeof(float));
	for (i = 0; i < duration; i++)
		if (obs[i] > 0)
			obsVar[i] = 40;
		else {
			obs[i] = means;
			obsVar[i] = 250000;
		}
	seqVar = 1e+2;
	initMean = fmini(obs, duration) + (fmaxi(obs, duration) - fmini(obs,
			duration)) / 2;
	initVar = (fmaxi(obs, duration) - fmini(obs, duration)) * (fmaxi(obs,
			duration) - fmini(obs, duration));
	stateMean = (float *) calloc(duration, sizeof(float));
	stateVar = (float *) calloc(duration, sizeof(float));
	stateMean[0] = (obs[0] * initVar + initMean * obsVar[0]) / (initVar
			+ obsVar[0]);
	stateVar[0] = initVar * obsVar[0] / (initVar + obsVar[0]);

	/* Filter loop */
	for (i = 1; i < duration; i++) {
		predictor = seqVar + stateVar[i - 1];
		stateMean[i] = (obs[i] * predictor + stateMean[i - 1] * obsVar[i])
				/ (predictor + obsVar[i]);
		stateVar[i] = predictor * obsVar[i] / (predictor + obsVar[i]);
	}

	/* Smoother loop */
	for (i = duration - 2; i >= 0; i--) {
		stateMean[i] = stateMean[i + 1] * stateVar[i] + stateMean[i] * seqVar;
		stateMean[i] /= seqVar + stateVar[i];
		J = stateVar[i] / (stateVar[i] + seqVar);
		stateVar[i] = J * (seqVar + J * stateVar[i + 1]);
	}

	for (i = 0; i < duration; i++) {
		obs[i] = stateMean[i];
	}

	/* free */
	free(stateVar);
	free(stateMean);
	free(obsVar);
}

void Usage(void) {
	fprintf(stderr, "\n");
	fprintf(stderr, "Legendre_Stylizer - The pitch target stylizer.\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "  usage:\n");
	fprintf(stderr, "       Legendre_Stylizer [ options ] \n");
	fprintf(
			stderr,
			"  options:                                                                   [  def][ min--max]\n");
	fprintf(
			stderr,
			"    -l lab         : file name of label with time information                [  N/A]\n");
	fprintf(
			stderr,
			"    -f lf0         : input name of logarithm f0 file                         [  N/A]\n");
	fprintf(
			stderr,
			"    -q dlop        : input name of quantized dlop file (to overwrite tgt)    [  N/A]\n");	
	fprintf(
			stderr,
			"    -t tgt         : file name of output target parameters                   [  N/A]\n");
	fprintf(
			stderr,
			"    -p pit         : file name of output continuous pitch                    [  N/A]\n");
	fprintf(
			stderr,
			"    -e err         : file name of output error monitor                       [  N/A]\n");
	fprintf(
			stderr,
			"    -n order       : order of Legendre polynomial                            [   %d][ 2--4]\n",
			ORDER);
	fprintf(
			stderr,
			"    -s             : using smoother option ( for discontinuous pitch )       [FALSE]\n");
	fprintf(stderr, "  note:\n");
	fprintf(stderr,
			"    label file should contain identical time information \n");
	fprintf(stderr,
			"    with the input lf0 file.                             \n");
	fprintf(stderr, "\n");

	exit(0);
}

void main(int argc, char **argv) {
	FILE *flf0 = NULL, *flab = NULL, *fqnt = NULL, *ftgt = NULL, *fpit = NULL, *ferr = NULL;
	float *pitch = NULL, *decpitch = NULL, **legcoef, **cores;
	char label[MAX_LEN];
	int order = ORDER, nframes = 0, nsyl = 0, start = 0, end = 0;
	int i, j, t, N;
	float sum, inter, len;
	int smooth = 0;

	if (argc < 5)
		Usage();
	/* read command */
	while (--argc) {
		if (**++argv == '-') {
			switch (*(*argv + 1)) {
			case 'l':
				flab = fopen(*++argv, "r");
				--argc;
				break;
			case 'f':
				flf0 = fopen(*++argv, "rb");
				--argc;
				break;
			case 'q':
				fqnt = fopen(*++argv, "rb");
				--argc;
				break;				
			case 't':
				ftgt = fopen(*++argv, "wb");
				--argc;
				break;
			case 'p':
				fpit = fopen(*++argv, "w");
				--argc;
				break;
			case 'e':
				ferr = fopen(*++argv, "w");
				--argc;
				break;
			case 'n':
				order = atoi(*++argv);
				--argc;
				break;
			case 's':
				smooth = atoi(*++argv);
				break;
			default:
				printf("Legendre_Stylizer: Invalid option '-%c'.\n",
						*(*argv + 1));
				exit(0);
			}
		}
	}
	if (flab == NULL || flf0 == NULL || ftgt == NULL) {
		printf("File not ready. Please check.\n");
		exit(0);
	}

	fseek(flf0, 0, SEEK_END);
	nframes = ftell(flf0) / sizeof(float);
	fseek(flf0, 0, SEEK_SET);
	pitch = (float *) calloc(nframes, sizeof(float));
	decpitch = (float *) calloc(nframes, sizeof(float));
	for (i = 0; i < nframes; i++) {
		fread(&pitch[i], sizeof(float), 1, flf0);
		/* if (fpit != NULL) */
		/* 	 fprintf(fpit, "%f\n", pitch[i]); */
	}
	fclose(flf0);

	if (smooth == 1)
		kalman(pitch, nframes);

	if (smooth == 1 && fpit != NULL) {
		for (i = 0; i < nframes; i++)
			fprintf(fpit, "%f\n", pitch[i]);
		fclose(fpit);
	}

	while (fgets(label, MAX_LEN, flab) != NULL)
		nsyl++;
	fseek(flab, 0, SEEK_SET);
	legcoef = (float **) calloc(nsyl, sizeof(float *));
	for (i = 0; i < nsyl; i++)
		legcoef[i] = (float *) calloc(order, sizeof(float));

	for (i = 0; i < nsyl; i++) {

		/* parse tempo info */
		fgets(label, MAX_LEN, flab);
		start = atoi(strtok(label, " ")) / FRAME_LEN;
		end = atoi(strtok(NULL, " ")) / FRAME_LEN;

		N = end - start + 1;
		len = (float) (N - 1);
		cores = (float **) calloc(N, sizeof(float *));
		for (t = 0; t < N; t++)
			cores[t] = (float *) calloc(order, sizeof(float));
		/* calculate Legendre polynomial functions */
		for (t = 0; t < N; t++) {
			inter = (float) t / len;
			for (j = 0; j < order; j++) {
				switch (j) {
				case 0:
					cores[t][j] = 1.0;
					break;
				case 1:
					cores[t][j] = sqrt(12.0 * len / (len + 2)) * (inter - 0.5);
					break;
				case 2:
					cores[t][j] = sqrt(
							180.0 * pow(len, 3) / ((len - 1) * (len + 2) * (len
									+ 3))) * (pow(inter, 2) - inter + (len - 1)
							/ (6 * len));
					break;
				case 3:
					cores[t][j] = sqrt(
							2800.0 * pow(len, 5) / ((len - 1) * (len - 2)
									* (len + 2) * (len + 3) * (len + 4)))
							* (pow(inter, 3) - 1.5 * pow(inter, 2) + (6 * len
									* len - 3 * len + 2) * inter / (10 * len
									* len) - (len - 1) * (len - 2) / (20 * len
									* len));
					break;
				}
			}
		}
		/* calculate Legendre coefficients */
		for (j = 0; j < order; j++) {
			sum = 0.0;
			for (t = 0; t < N; t++) {
				sum += pitch[start + t] * cores[t][j];
			}
			legcoef[i][j] = sum / N;
		}

		/* output parameter */
		for (j = 0; j < order; j++)
			fwrite(&legcoef[i][j], sizeof(float), 1, ftgt);
		
		if (fqnt != NULL) {
			for (j = 0; j < order; j++)
				fread(&legcoef[i][j], sizeof(float), 1, fqnt);
		}

		/* calculate Legendre approximations */
		for (t = 0; t < N; t++) {
			sum = 0.0;
			for (j = 0; j < order; j++)
				sum += legcoef[i][j] * cores[t][j];
			decpitch[t] = sum;
		}
		if (fpit != NULL) {
			for (t = 0; t < N; t++)
				fprintf(fpit, "%f\n", decpitch[t]);
		}

		/* output parameter */
//		for (j = 0; j < order; j++)
//			fwrite(&legcoef[i][j], sizeof(float), 1, ftgt);

		if (ferr != NULL)
			fprintf(ferr, "\n");

		/* free */
		for (t = 0; t < N; t++)
			free(cores[t]);
		free(cores);
	}

	for (i = 0; i < nsyl; i++)
		free(legcoef[i]);
	free(legcoef);
	fclose(flab);
	fclose(ftgt);
	if (fpit != NULL)
		fclose(fpit);
	if (fqnt != NULL)
		fclose(fqnt);
	if (ferr != NULL)
		fclose(ferr);
	free(pitch);
	free(decpitch);
}
