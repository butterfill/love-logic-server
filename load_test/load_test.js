meteorDown.init(function (Meteor) {
  Meteor.subscribe('dates_exercises_submitted', Meteor.userId(), function (error, result) {
    Meteor.kill();
  });
});

meteorDown.run({
  concurrency: 10,
  url: "http://love-logic.butterfill.com",
  key: "2FkY2M5YjNiYzUzM",
  auth: {userIds:[
    "28qCXS5fQkuegy2XK",
    "9Q7k8CvSCFfBreoDg",
    "iZ7HrSudFqbdWv7Cf",
    "ng3iCQ8sgfZLLJ2vu",
    "zzWkWTQRSF8vvqXBp",
    "zh6hXtnBk54c9r3pK",
    "nSXHvHihtjyn7ES8k",
    "kjheqPHziKia8hDsN",
    "sBQPaqKE7mNtj3ReX",
    "yurXPdsgdpmstzHxs"
  ]}
});

