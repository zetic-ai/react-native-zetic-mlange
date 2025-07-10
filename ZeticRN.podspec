require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "ZeticRN"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => ".git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

# Use install_modules_dependencies helper to install the dependencies if React Native version >=0.71.0.
# See https://github.com/facebook/react-native/blob/febf6b7f33fdb4904669f99d795eba4c0f95d7bf/scripts/cocoapods/new_architecture.rb#L79.
if respond_to?(:install_modules_dependencies, true)
  install_modules_dependencies(s)
else
  s.dependency "React-Core"
end


framework_name = "ZeticMLange"
repo_path = "zetic-ai/ZeticMLangeiOS"
framework_dir = "ios/Frameworks"
version = "1.2.2"

s.prepare_command = <<-CMD
set -e  # Exit on any error

# Variables
FRAMEWORK_NAME="#{framework_name}"
REPO="#{repo_path}"
VERSION="#{version}"
FRAMEWORK_DIR="#{framework_dir}"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${FRAMEWORK_NAME}.xcframework.zip"
FRAMEWORK_PATH="${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"

echo "📦 Installing ${FRAMEWORK_NAME} v${VERSION}..."

# Clean setup
rm -rf "${FRAMEWORK_PATH}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
mkdir -p "${FRAMEWORK_DIR}"

# Create log file
LOG_FILE="zeticmlange_installation.log"
if [ -d ${LOG_FILE} ]; then
  rm ${LOG_FILE}
fi
# Download and extract
echo "⬇️  Downloading from: ${DOWNLOAD_URL}"
curl -fL "${DOWNLOAD_URL}" -o "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
unzip -q "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip" -d "${FRAMEWORK_DIR}/"
rm "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"

# Verify
if [ -d "${FRAMEWORK_PATH}" ]; then
  echo "✅ Framework installed successfully at: ${FRAMEWORK_PATH}"
else
  echo "❌ Installation failed: Framework not found at ${FRAMEWORK_PATH}"
  exit 1
fi
CMD

s.vendored_frameworks = "ios/Frameworks/ZeticMLange.xcframework"

end
