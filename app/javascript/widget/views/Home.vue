<script>
import TeamAvailability from 'widget/components/TeamAvailability.vue';
import { mapGetters } from 'vuex';
import { useRouter } from 'vue-router';
import configMixin from 'widget/mixins/configMixin';
import ArticleContainer from '../components/pageComponents/Home/Article/ArticleContainer.vue';
export default {
  name: 'Home',
  components: {
    ArticleContainer,
    TeamAvailability,
  },
  mixins: [configMixin],
  setup() {
    const router = useRouter();
    return { router };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationSize: 'conversation/getConversationSize',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
    }),
  },
  async mounted() {
    // Auto-create conversation and go directly to chat (skip home screen)
    // This gives the Zendesk-like experience where the first message with buttons
    // appears immediately when the visitor opens the widget
    if (this.preChatFormEnabled && !this.conversationSize) {
      // If pre-chat form is enabled, let the user fill it first
      return;
    }
    if (!this.conversationSize) {
      try {
        await this.$store.dispatch('conversation/createConversation', {
          fullName: '',
          emailAddress: '',
          phoneNumber: '',
          message: '',
        });
      } catch (e) {
        // ignore creation errors
      }
    }
    // Always redirect to messages view
    this.router.replace({ name: 'messages' });
  },
  methods: {
    async startConversation() {
      if (this.preChatFormEnabled && !this.conversationSize) {
        return this.router.replace({ name: 'prechat-form' });
      }
      // If no conversation exists, create one silently to trigger the flow
      if (!this.conversationSize) {
        try {
          await this.$store.dispatch('conversation/createConversation', {
            fullName: '',
            emailAddress: '',
            phoneNumber: '',
            message: '',
          });
        } catch (e) {
          // ignore
        }
      }
      return this.router.replace({ name: 'messages' });
    },
  },
};
</script>

<template>
  <div class="z-50 flex flex-col justify-end flex-1 w-full p-4 gap-4">
    <TeamAvailability
      :available-agents="availableAgents"
      :has-conversation="!!conversationSize"
      :unread-count="unreadMessageCount"
      @start-conversation="startConversation"
    />

    <ArticleContainer />
  </div>
</template>
