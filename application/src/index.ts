import * as express from 'express';
import 'express-async-errors';
import * as promBundle from 'express-prom-bundle';


const app = express();
const metricsMiddleware = promBundle({
  buckets: [0.1, 0.4, 0.7],
  includeMethod: true,
  includePath: true
});

app.use(metricsMiddleware);

app.get('/', (req: express.Request, res: express.Response) => {
  const response = {
    hostname: req.hostname,
    uptime: process.uptime(),
    podname: process.env.HOSTNAME,
  };

  res.status(200).send(response);
});


app.listen(3000, () => {
  console.log('listening on 3000');
});