/**
 * @file
 * Testing of an article creation with 15 paragraphs.
 */

/**
 * Module "elastic-apm-node" has to be installed for core.
 *
 * You can use Yarn command for that: yarn add elastic-apm-node --dev
 * and it will install that module with it's requirements.
 *
 * We are using "process.cwd()" to get core directory.
 */
// eslint-disable-next-line import/no-dynamic-require
const apm = require(`${process.cwd()}/node_modules/elastic-apm-node`);

module.exports = {
  "@tags": ["Standard"],
  before(browser, done) {
    browser.apm = apm;

    done();
  },
  createAnArticleInStandard(browser) {
    browser
      .resizeWindow(1024, 1024)
      .performance.startMeasurement(
        process.env.THUNDER_APM_URL,
        "Create an article in standard",
        `.${process.env.THUNDER_SITE_HOSTNAME}`
      )
      .performance.startMark("full task")
      .performance.startMark("login")
      .drupalLogin({ name: "admin", password: "admin" })
      .performance.endMark()

      .performance.startMark("create article")
      .drupalRelativeURL("/node/add/article")
      // Start using XPATH!!!
      .useXpath()
      .performance.startMark("create article basic fields")
      .setValue(
        '//*[@id="edit-title-0-value"]',
        "Lorem Cat Sum 10. Reasons why cats ipsum"
      )
      .performance.endMark()
      // Submit form.
      .click('//*[@id="edit-submit"]')
      .useCss()
      .waitForElementVisible('body', 10000)
      .assert.containsText('div.messages', 'has been created')
      .performance.endMeasurement();

    browser.end();
  }
};
