from prefect import task, flow, get_run_logger

import boto3
import time


client = boto3.client('emr-serverless')


@task
def create_application():
	response = client.create_application(
		name="emr-test-app",
		releaseLabel="emr-6.13.0",
		type="SPARK"
	)
	return response['applicationId']


@task
def start_application(application_id):
	client.start_application(applicationId=application_id)
	

@task
def submit_spark_job(application_id):
	response = client.start_job_run(
		applicationId=application_id,
		executionRoleArn="arn:aws:iam::00000000000:role/EMRServerlessS3RuntimeRole",
		jobDriver={
			"sparkSubmit": {
				# will be using another DC job script instead of sample wordcount.py
				"entryPoint": "s3://fake-bucket/scripts/myjob.py",
				"entryPointArguments": ["s3://fake-bucket/output"],
				# manual override resources
				"sparkSubmitParameters": "--conf spark.executor.cores=1 --conf spark.executor.memory=4g --conf spark.driver.cores=1 --conf spark.driver.memory=4g --conf spark.executor.instances=1",
			}
		},
		configurationOverrides={
			"monitoringConfiguration": {
				"s3MonitoringConfiguration": {"logUri": "s3://fake-bucket/logs"}
			}
		},
	)
	return response['jobRunId']


@task
def check_job_status(application_id, job_id):
	logger = get_run_logger()
	job_completed = False

	while not job_completed:
		response = client.get_job_run(applicationId=application_id, jobRunId=job_id)
		job_state = response['jobRun']['state']
		logger.info(job_state + '...')
		if job_state in ['SUCCESS', 'CANCELLED', 'FAILED']:
			job_completed = True
		if not job_completed:
			time.sleep(30)


@task
def stop_delete_application(application_id):
	logger = get_run_logger()
	client.stop_application(applicationId=application_id)
	app_stopped = False

	while not app_stopped:
		response = client.get_application(applicationId=application_id)
		app_state = response['application']['state']
		logger.info(app_state + '...')
		if app_state == 'STOPPED':
			app_stopped = True
		if not app_stopped:
			time.sleep(30)

	client.delete_application(applicationId=application_id)
	

@flow
def emr_flow():
	logger = get_run_logger()
	app_id = create_application()
	logger.info(f"EMR cluster created with applicationId: {app_id}")

	start_application(app_id)
	logger.info(f"EMR cluster started with applicationId: {app_id}")

	job_id = submit_spark_job(app_id)
	logger.info(f"Submitted Spark Job to EMR cluster with applicationId: {app_id}")

	check_job_status(app_id, job_id)
	logger.info(f"Completed Spark Job")

	stop_delete_application(app_id)
	logger.info(f"Stopped and Deleted EMR cluster with applicationId: {app_id}")


if __name__ == "__main__":
	emr_flow()













