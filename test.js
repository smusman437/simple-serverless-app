const https = require("https");
const { execSync } = require("child_process");

// Get API URL from Pulumi stack output
let apiUrl;
try {
  apiUrl = execSync("pulumi stack output apiUrl", { encoding: "utf8" }).trim();
  console.log("🔗 API URL:", apiUrl);
} catch (error) {
  console.error("❌ Failed to get API URL. Make sure the stack is deployed.");
  process.exit(1);
}

// Helper function to make HTTP requests
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on("error", reject);

    if (options.body) {
      req.write(options.body);
    }

    req.end();
  });
}

// Test suite
async function runTests() {
  console.log("\n🧪 Running API Tests...\n");

  try {
    // Test 1: Health Check
    console.log("1️⃣ Testing health endpoint...");
    const health = await makeRequest(`${apiUrl}/health`);
    if (health.status === 200 && health.data.ok) {
      console.log("✅ Health check passed");
      console.log("   Response:", JSON.stringify(health.data, null, 2));
    } else {
      console.log("❌ Health check failed");
      console.log("   Status:", health.status);
      console.log("   Response:", health.data);
    }

    // Test 2: Get empty users list
    console.log("\n2️⃣ Testing empty users list...");
    const emptyUsers = await makeRequest(`${apiUrl}/users`);
    if (emptyUsers.status === 200) {
      console.log("✅ Users list retrieved");
      console.log("   Count:", emptyUsers.data.count || 0);
    } else {
      console.log("❌ Failed to get users list");
      console.log("   Status:", emptyUsers.status);
    }

    // Test 3: Create a user
    console.log("\n3️⃣ Testing user creation...");
    const newUser = await makeRequest(`${apiUrl}/users`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: "Test User",
        email: "test@example.com",
      }),
    });

    if (newUser.status === 201) {
      console.log("✅ User created successfully");
      console.log("   User ID:", newUser.data.id);
      console.log("   Name:", newUser.data.name);
      console.log("   Email:", newUser.data.email);

      // Test 4: Get the created user
      console.log("\n4️⃣ Testing user retrieval...");
      const getUser = await makeRequest(`${apiUrl}/users/${newUser.data.id}`);
      if (getUser.status === 200 && getUser.data.id === newUser.data.id) {
        console.log("✅ User retrieved successfully");
        console.log("   Retrieved user:", getUser.data.name);
      } else {
        console.log("❌ Failed to retrieve user");
        console.log("   Status:", getUser.status);
      }

      // Test 5: Get users list (should have 1 user now)
      console.log("\n5️⃣ Testing users list with data...");
      const users = await makeRequest(`${apiUrl}/users`);
      if (users.status === 200 && users.data.count > 0) {
        console.log("✅ Users list with data retrieved");
        console.log("   Count:", users.data.count);
        console.log("   First user:", users.data.users[0].name);
      } else {
        console.log("❌ Failed to get users list with data");
        console.log("   Status:", users.status);
      }
    } else {
      console.log("❌ Failed to create user");
      console.log("   Status:", newUser.status);
      console.log("   Response:", newUser.data);
    }

    // Test 6: Get bucket info
    console.log("\n6️⃣ Testing bucket endpoint...");
    const bucket = await makeRequest(`${apiUrl}/bucket`);
    if (bucket.status === 200) {
      console.log("✅ Bucket info retrieved");
      console.log("   Bucket:", bucket.data.bucketName);
      console.log("   Region:", bucket.data.region);
    } else {
      console.log("❌ Failed to get bucket info");
      console.log("   Status:", bucket.status);
    }

    // Test 7: 404 handling
    console.log("\n7️⃣ Testing 404 handling...");
    const notFound = await makeRequest(`${apiUrl}/nonexistent`);
    if (notFound.status === 404) {
      console.log("✅ 404 handling works correctly");
    } else {
      console.log("❌ Unexpected response for nonexistent route");
      console.log("   Status:", notFound.status);
    }

    console.log("\n🎉 All tests completed!");
  } catch (error) {
    console.error("❌ Test suite failed:", error.message);
    process.exit(1);
  }
}

// Run the tests
runTests();
