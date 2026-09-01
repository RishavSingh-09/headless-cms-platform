module.exports = ({ env }) => ({
  upload: {
    config: {
      provider: 'aws-s3',
      providerOptions: {
        accessKeyId: env('AWS_ACCESS_KEY_ID'),
        secretAccessKey: env('AWS_SECRET_ACCESS_KEY'),
        region: env('AWS_REGION', 'ap-south-1'),
        params: { Bucket: env('AWS_S3_BUCKET', 'cms-media-dev') },
      },
    },
  },
});
