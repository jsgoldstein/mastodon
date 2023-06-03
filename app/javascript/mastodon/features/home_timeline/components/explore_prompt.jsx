import React from 'react';

import { FormattedMessage } from 'react-intl';

import { Link } from 'react-router-dom';

import DismissableBanner from 'mastodon/components/dismissable_banner';

export const ExplorePrompt = () => (
  <DismissableBanner id='home.explore_prompt'>
    <p><FormattedMessage id='home.explore_prompt' defaultMessage="Your home feed is all the people you follow and the posts they share. It becomes more useful when you follow more people. It looks like it's not very lively yet, so how about:" /></p>

    <div className='dismissable-banner__message__actions'>
      <Link to='/explore' className='button'><FormattedMessage id='home.actions.go_to_explore' defaultMessage="See what's trending" /></Link>
      <Link to='/explore/suggestions' className='button button-tertiary'><FormattedMessage id='home.actions.go_to_suggestions' defaultMessage='Find people to follow' /></Link>
    </div>
  </DismissableBanner>
);