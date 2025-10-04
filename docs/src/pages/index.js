import React from 'react';
import Layout from '@theme/Layout';

function Home() {
  return (
    <Layout
      title="Welcome"
      description="FlorisBoard Documentation Home Page">
      <main>
        <div
          style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '50vh',
            fontSize: '20px',
          }}>
          <p>
            Welcome to the FlorisBoard Documentation!
          </p>
        </div>
      </main>
    </Layout>
  );
}

export default Home;
