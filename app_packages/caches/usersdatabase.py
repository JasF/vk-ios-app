from .basedatabase import BaseDatabase

class UsersDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'users'
    
    def params(self):
        return {'first_name': 'text', 'last_name': 'text', 'sex': 'integer', 'nickname': 'text', 'domain': 'text', 'screen_name': 'text', 'bdate': 'text', 'city': 'text', 'country': 'text', 'timezone': 'integer', 'photo_50': 'text', 'photo_100': 'text', 'photo_200': 'text', 'photo_max': 'text', 'photo_200_orig': 'text', 'photo_400_orig': 'text', 'photo_max_orig': 'text', 'photo_id': 'text', 'has_photo': 'integer', 'has_mobile': 'integer', 'is_friend': 'integer', 'friend_status': 'integer', 'online': 'integer', 'wall_comments': 'integer', 'can_post': 'integer', 'can_see_all_posts': 'integer', 'can_see_audio': 'integer', 'can_write_private_message': 'integer', 'can_send_friend_request': 'integer', 'mobile_phone': 'text', 'home_phone': 'text', 'skype': 'text', 'site': 'text', 'status': 'text', 'last_seen': 'text', 'crop_photo': 'text', 'verified': 'integer', 'followers_count': 'integer', 'blacklisted': 'integer', 'blacklisted_by_me': 'integer', 'is_favorite': 'integer', 'is_hidden_from_feed': 'integer', 'common_count': 'integer', 'career': 'text', 'military': 'text', 'university': 'integer', 'university_name': 'text', 'faculty': 'integer', 'faculty_name': 'text', 'graduation': 'integer', 'home_town': 'text', 'relation': 'integer', 'personal': 'text', 'interests': 'text', 'music': 'text', 'activities': 'text', 'movies': 'text', 'tv': 'text', 'books': 'text', 'games': 'text', 'universities': 'text', 'schools': 'text', 'about': 'text', 'relatives': 'text', 'quotes': 'text', 'name': 'text', 'friends_count': 'integer', 'photos_count': 'integer', 'videos_count': 'integer', 'subscriptions_count': 'integer', 'groups_count': 'integer'}
    
    def objects(self):
        return ['city', 'country', 'last_seen', 'crop_photo', 'career', 'military', 'personal', 'universities', 'schools', 'relatives']
    
    def getShortUsersByIds(self, ids):
        return self.selectIdsByKeys(ids, ['id','first_name','last_name','photo_50','photo_100','photo_200','name'])
