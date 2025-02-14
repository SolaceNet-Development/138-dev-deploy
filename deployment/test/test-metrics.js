const axios = require('axios');
require('dotenv').config();

async function testMetrics() {
    console.log('Testing Prometheus Metrics...');
    
    // Test Besu metrics
    const besuMetrics = await axios.get('http://localhost:9545/metrics');
    console.log('Besu metrics available:', besuMetrics.status === 200);
    
    // Test Grafana dashboards
    const grafanaHealth = await axios.get('http://localhost:3000/api/health');
    console.log('Grafana health check:', grafanaHealth.status === 200);
    
    // Test node performance
    const nodeMetrics = await axios.get('http://localhost:9545/metrics/node');
    console.log('Node performance metrics:', nodeMetrics.status === 200);
    
    // Test network metrics
    const networkMetrics = await axios.get('http://localhost:9545/metrics/network');
    console.log('Network metrics:', networkMetrics.status === 200);
    
    console.log('All metrics tests passed');
}

testMetrics()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
