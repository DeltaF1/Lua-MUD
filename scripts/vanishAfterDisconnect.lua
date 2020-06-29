-- filter(vanishAfterPuppet)
return {
  methods = {
    onUnpuppet = {
      function(self, args, ret)
        self.room:broadcast(self.name.." dissapears beyond the looking glass", self)
        self.room:remove(self)
        db.store_object(self)
      end
    },
  },
}
